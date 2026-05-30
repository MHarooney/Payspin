#!/usr/bin/env bash
# Deploy Payspin stack to Hetzner VPS.
# Builds locally, streams image to server (no Docker Hub push required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SSH_KEY="${PAYSPIN_SSH_KEY:-$HOME/.ssh/id_ed25519_payspin}"
SERVER_IP="${PAYSPIN_SERVER_IP:-}"
HCLOUD_TOKEN="${HCLOUD_TOKEN:-}"
IMAGE="${DOCKER_IMAGE:-payspin/api:latest}"
REMOTE_DIR="/opt/payspin"

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

echo "==> Building ${IMAGE}"
docker build -f "$ROOT/backend/Dockerfile" -t "$IMAGE" "$ROOT"

echo "==> Preparing server ${SERVER_IP}"
"${SSH[@]}" 'command -v docker >/dev/null || (
  apt-get update -qq && apt-get install -y -qq ca-certificates curl
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
)'

echo "==> Loading image on server"
docker save "$IMAGE" | gzip | "${SSH[@]}" 'gunzip | docker load'

echo "==> Uploading compose + Caddyfile"
"${SSH[@]}" "mkdir -p ${REMOTE_DIR}"
"${SCP[@]}" "$ROOT/infrastructure/docker/docker-compose.prod.yml" "root@${SERVER_IP}:${REMOTE_DIR}/docker-compose.yml"
"${SCP[@]}" "$ROOT/infrastructure/docker/Caddyfile" "root@${SERVER_IP}:${REMOTE_DIR}/Caddyfile"

if "${SSH[@]}" "test -f ${REMOTE_DIR}/.env.production"; then
  echo "    Keeping existing ${REMOTE_DIR}/.env.production"
else
  PG_PASS="$(openssl rand -hex 16)"
  JWT_SECRET="$(openssl rand -hex 32)"
  IBAN_KEY="$(openssl rand -hex 32)"
  API_BASE="http://${SERVER_IP}"
  PAYER_WEB="${PAYER_WEB_URL:-http://${SERVER_IP}}"

  ENV_FILE="$(mktemp)"
  trap 'rm -f "$ENV_FILE"' EXIT
  cat >"$ENV_FILE" <<EOF
POSTGRES_USER=payspin
POSTGRES_PASSWORD=${PG_PASS}
POSTGRES_DB=payspin
DATABASE_URL=postgresql://payspin:${PG_PASS}@postgres:5432/payspin?schema=public
REDIS_URL=redis://redis:6379
PORT=3001
NODE_ENV=production
API_BASE_URL=${API_BASE}
PAYER_WEB_URL=${PAYER_WEB}
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
EOF
  "${SCP[@]}" "$ENV_FILE" "root@${SERVER_IP}:${REMOTE_DIR}/.env.production"
fi

echo "==> Starting stack"
"${SSH[@]}" "cd ${REMOTE_DIR} && docker compose up -d --remove-orphans"

echo "==> Waiting for health"
for _ in $(seq 1 36); do
  if curl -sf "http://${SERVER_IP}/v1/health" >/dev/null 2>&1; then
    echo ""
    echo "Deployed successfully."
    echo "  Health: http://${SERVER_IP}/v1/health"
    echo "  SSH:    ssh -i ${SSH_KEY} root@${SERVER_IP}"
    exit 0
  fi
  sleep 5
done

echo "Health check timed out. Logs:" >&2
"${SSH[@]}" "cd ${REMOTE_DIR} && docker compose ps && docker compose logs --tail=50 api" >&2
exit 1
