#!/usr/bin/env bash
# Deploy Payspin stack to Hetzner VPS.
# Builds locally (Mac), pushes to Docker Hub, server pulls and runs compose.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SSH_KEY="${PAYSPIN_SSH_KEY:-$HOME/.ssh/id_ed25519_payspin}"
SERVER_IP="${PAYSPIN_SERVER_IP:-}"
HCLOUD_TOKEN="${HCLOUD_TOKEN:-}"
IMAGE="${DOCKER_IMAGE:-payspin/api:latest}"
WEB_IMAGE="${DOCKER_WEB_IMAGE:-payspin/web:latest}"
OPS_API_IMAGE="${DOCKER_OPS_API_IMAGE:-payspin/ops-api:latest}"
OPS_WEB_IMAGE="${DOCKER_OPS_WEB_IMAGE:-payspin/ops-web:latest}"
REMOTE_DIR="/opt/payspin"
# Hetzner CX servers are amd64; Mac dev machines often build arm64 by default.
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
# Domains for HTTPS (optional). Leave SITE_ADDRESS empty for IP-only payer deploy.
SITE_ADDRESS="${SITE_ADDRESS:-pay.payspin.io}"
OPS_SITE_ADDRESS="${OPS_SITE_ADDRESS:-ops.payspin.io}"

if [[ -z "$SERVER_IP" && -n "$HCLOUD_TOKEN" ]]; then
  export HCLOUD_TOKEN
  SERVER_IP="$(hcloud server ip "${HCLOUD_SERVER_NAME:-payspin-api}" 2>/dev/null || true)"
fi

if [[ -z "$SERVER_IP" ]]; then
  echo "Set PAYSPIN_SERVER_IP or run provision.sh with HCLOUD_TOKEN first." >&2
  exit 1
fi

if [[ ! -f "$SSH_KEY" ]]; then
  echo "Missing SSH key: $SSH_KEY" >&2
  exit 1
fi

SSH=(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "root@${SERVER_IP}")
SCP=(scp -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new)

# Public origin the payer browser uses to reach the API (baked into the web bundle).
if [[ -n "$SITE_ADDRESS" ]]; then
  PUBLIC_API_URL="https://${SITE_ADDRESS}/v1"
  PUBLIC_WEB_URL="https://${SITE_ADDRESS}"
  PUBLIC_OPS_API_URL="https://${OPS_SITE_ADDRESS}/admin/v1"
  PUBLIC_OPS_WEB_URL="https://${OPS_SITE_ADDRESS}"
else
  PUBLIC_API_URL="http://${SERVER_IP}/v1"
  PUBLIC_WEB_URL="http://${SERVER_IP}"
  PUBLIC_OPS_API_URL="http://${SERVER_IP}/admin/v1"
  PUBLIC_OPS_WEB_URL="http://${SERVER_IP}"
fi

echo "==> Building ${IMAGE} (${DOCKER_PLATFORM})"
docker build --platform "$DOCKER_PLATFORM" -f "$ROOT/backend/Dockerfile" -t "$IMAGE" "$ROOT"

echo "==> Building ${WEB_IMAGE} (NEXT_PUBLIC_API_URL=${PUBLIC_API_URL}, ${DOCKER_PLATFORM})"
docker build --platform "$DOCKER_PLATFORM" -f "$ROOT/frontend/Dockerfile" \
  --build-arg "NEXT_PUBLIC_API_URL=${PUBLIC_API_URL}" \
  -t "$WEB_IMAGE" "$ROOT"

echo "==> Preparing server ${SERVER_IP}"
"${SSH[@]}" 'command -v docker >/dev/null || (
  apt-get update -qq && apt-get install -y -qq ca-certificates curl
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
)'

echo "==> Pushing images to Docker Hub"
docker push "$IMAGE"
docker push "$WEB_IMAGE"

echo "==> Pulling images on server (no build on server)"
"${SSH[@]}" "docker pull ${IMAGE} && docker pull ${WEB_IMAGE}"

echo "==> Uploading compose + Caddyfile"
"${SSH[@]}" "mkdir -p ${REMOTE_DIR}"
"${SCP[@]}" "$ROOT/infrastructure/docker/docker-compose.prod.yml" "root@${SERVER_IP}:${REMOTE_DIR}/docker-compose.yml"
"${SCP[@]}" "$ROOT/infrastructure/docker/Caddyfile" "root@${SERVER_IP}:${REMOTE_DIR}/Caddyfile"
"${SCP[@]}" "$ROOT/infrastructure/docker/backup.sh" "root@${SERVER_IP}:${REMOTE_DIR}/backup.sh"
"${SSH[@]}" "chmod +x ${REMOTE_DIR}/backup.sh"

echo "==> Installing daily database backup cron (03:15)"
# Idempotent: replace any existing payspin backup line, keep other cron jobs.
"${SSH[@]}" "( crontab -l 2>/dev/null | grep -v 'payspin/backup.sh' ; \
  echo '15 3 * * * cd ${REMOTE_DIR} && ./backup.sh >> /var/log/payspin-backup.log 2>&1' ) | crontab -"

if "${SSH[@]}" "test -f ${REMOTE_DIR}/.env.production"; then
  echo "    Keeping existing ${REMOTE_DIR}/.env.production"
else
  PG_PASS="$(openssl rand -hex 16)"
  REDIS_PASS="$(openssl rand -hex 16)"
  JWT_SECRET="$(openssl rand -hex 32)"
  IBAN_KEY="$(openssl rand -hex 32)"
  API_BASE="${PUBLIC_WEB_URL}"
  PAYER_WEB="${PAYER_WEB_URL:-${PUBLIC_WEB_URL}}"

  ENV_FILE="$(mktemp)"
  trap 'rm -f "$ENV_FILE"' EXIT
  cat >"$ENV_FILE" <<EOF
POSTGRES_USER=payspin
POSTGRES_PASSWORD=${PG_PASS}
POSTGRES_DB=payspin
DATABASE_URL=postgresql://payspin:${PG_PASS}@postgres:5432/payspin?schema=public
REDIS_PASSWORD=${REDIS_PASS}
REDIS_URL=redis://:${REDIS_PASS}@redis:6379
PORT=3001
NODE_ENV=production
SITE_ADDRESS=${SITE_ADDRESS:-pay.payspin.io}
OPS_SITE_ADDRESS=${OPS_SITE_ADDRESS:-ops.payspin.io}
ACME_EMAIL=${ACME_EMAIL:-payspin.app@gmail.com}
API_BASE_URL=${API_BASE}
PAYER_WEB_URL=${PAYER_WEB}
OPS_CORS_ORIGIN=${PUBLIC_OPS_WEB_URL}
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET:-$(openssl rand -hex 32)}
ADMIN_JWT_EXPIRES_IN=15m
MOBILE_CONNECT_REDIRECT=${MOBILE_CONNECT_REDIRECT:-payspin://bank-callback}
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRES_IN=7d
IBAN_ENCRYPTION_KEY=${IBAN_KEY}
YAPILY_APP_KEY=
YAPILY_APP_SECRET=
YAPILY_WEBHOOK_SECRET=
YAPILY_BASE_URL=https://api.yapily.com
YAPILY_DEFAULT_INSTITUTION=modelo-sandbox
YAPILY_DEFAULT_COUNTRY=NL
DOCKER_IMAGE=${IMAGE}
DOCKER_WEB_IMAGE=${WEB_IMAGE}
DOCKER_OPS_API_IMAGE=${OPS_API_IMAGE}
DOCKER_OPS_WEB_IMAGE=${OPS_WEB_IMAGE}
# IP-only staging deploy: allow internal sandbox gateway until Yapily keys are set.
PAYSPIN_ALLOW_SANDBOX_GATEWAY=$([[ -z "$SITE_ADDRESS" ]] && echo true || echo false)
EOF
  "${SCP[@]}" "$ENV_FILE" "root@${SERVER_IP}:${REMOTE_DIR}/.env.production"
fi

echo "==> Ensuring ops env keys on server"
PATCH_ADMIN_JWT="$(openssl rand -hex 32)"
"${SSH[@]}" "cd ${REMOTE_DIR} && \
  grep -q '^OPS_SITE_ADDRESS=' .env.production 2>/dev/null || echo 'OPS_SITE_ADDRESS=${OPS_SITE_ADDRESS}' >> .env.production && \
  grep -q '^OPS_CORS_ORIGIN=' .env.production 2>/dev/null || echo 'OPS_CORS_ORIGIN=${PUBLIC_OPS_WEB_URL}' >> .env.production && \
  grep -q '^ADMIN_JWT_SECRET=' .env.production 2>/dev/null || echo 'ADMIN_JWT_SECRET=${PATCH_ADMIN_JWT}' >> .env.production && \
  grep -q '^ADMIN_JWT_EXPIRES_IN=' .env.production 2>/dev/null || echo 'ADMIN_JWT_EXPIRES_IN=15m' >> .env.production && \
  grep -q '^DOCKER_OPS_API_IMAGE=' .env.production 2>/dev/null || echo 'DOCKER_OPS_API_IMAGE=${OPS_API_IMAGE}' >> .env.production && \
  grep -q '^DOCKER_OPS_WEB_IMAGE=' .env.production 2>/dev/null || echo 'DOCKER_OPS_WEB_IMAGE=${OPS_WEB_IMAGE}' >> .env.production && \
  sed -i 's|^SITE_ADDRESS=.*|SITE_ADDRESS=${SITE_ADDRESS}|' .env.production"

echo "==> Starting payer stack (api + web + caddy; ops is deploy-ops.sh)"
# --env-file feeds compose interpolation (redis password, SITE_ADDRESS, etc.).
"${SSH[@]}" "cd ${REMOTE_DIR} && docker compose --env-file .env.production up -d --remove-orphans postgres redis api web caddy"

echo "==> Waiting for payer health"
for _ in $(seq 1 36); do
  if curl -sf "https://${SITE_ADDRESS}/v1/health/ready" >/dev/null 2>&1; then
    echo ""
    echo "Payer stack deployed successfully."
    echo "  Payer:  https://${SITE_ADDRESS}"
    echo "  Health: https://${SITE_ADDRESS}/v1/health/ready"
    echo "  Ops:    run ./infrastructure/hetzner/deploy-ops.sh"
    echo "  SSH:    ssh -i ${SSH_KEY} root@${SERVER_IP}"
    exit 0
  fi
  sleep 5
done

echo "Health check timed out. Logs:" >&2
"${SSH[@]}" "cd ${REMOTE_DIR} && docker compose ps && docker compose logs --tail=50 api" >&2
exit 1
