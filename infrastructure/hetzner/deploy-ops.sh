#!/usr/bin/env bash
# Deploy Payspin Ops portal only (ops-api + ops-web).
# Does not rebuild or restart the consumer api/web images.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SSH_KEY="${PAYSPIN_SSH_KEY:-$HOME/.ssh/id_ed25519_payspin}"
SERVER_IP="${PAYSPIN_SERVER_IP:-}"
HCLOUD_TOKEN="${HCLOUD_TOKEN:-}"
OPS_API_IMAGE="${DOCKER_OPS_API_IMAGE:-payspin/ops-api:latest}"
OPS_WEB_IMAGE="${DOCKER_OPS_WEB_IMAGE:-payspin/ops-web:latest}"
REMOTE_DIR="/opt/payspin"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
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

PUBLIC_OPS_API_URL="https://${OPS_SITE_ADDRESS}/admin/v1"
PUBLIC_OPS_WEB_URL="https://${OPS_SITE_ADDRESS}"
PUBLIC_PAYER_WEB_URL="${PAYER_WEB_URL:-https://pay.payspin.io}"

echo "==> Building ${OPS_API_IMAGE} (${DOCKER_PLATFORM})"
docker build --platform "$DOCKER_PLATFORM" -f "$ROOT/ops-portal/backend/Dockerfile" \
  -t "$OPS_API_IMAGE" "$ROOT"

echo "==> Building ${OPS_WEB_IMAGE} (NEXT_PUBLIC_OPS_API_URL=${PUBLIC_OPS_API_URL}, ${DOCKER_PLATFORM})"
docker build --platform "$DOCKER_PLATFORM" -f "$ROOT/ops-portal/frontend/Dockerfile" \
  --build-arg "NEXT_PUBLIC_OPS_API_URL=${PUBLIC_OPS_API_URL}" \
  --build-arg "NEXT_PUBLIC_PAYER_WEB_URL=${PUBLIC_PAYER_WEB_URL}" \
  -t "$OPS_WEB_IMAGE" "$ROOT"

echo "==> Pushing ops images to Docker Hub"
docker push "$OPS_API_IMAGE"
docker push "$OPS_WEB_IMAGE"

echo "==> Pulling ops images on server"
"${SSH[@]}" "docker pull ${OPS_API_IMAGE} && docker pull ${OPS_WEB_IMAGE}"

echo "==> Uploading compose + Caddyfile (ops routes)"
"${SSH[@]}" "mkdir -p ${REMOTE_DIR}"
"${SCP[@]}" "$ROOT/infrastructure/docker/docker-compose.prod.yml" "root@${SERVER_IP}:${REMOTE_DIR}/docker-compose.yml"
"${SCP[@]}" "$ROOT/infrastructure/docker/Caddyfile" "root@${SERVER_IP}:${REMOTE_DIR}/Caddyfile"

if ! "${SSH[@]}" "test -f ${REMOTE_DIR}/.env.production"; then
  echo "Missing ${REMOTE_DIR}/.env.production — run deploy.sh for the payer stack first." >&2
  exit 1
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
  grep -q '^CONSUMER_API_URL=' .env.production 2>/dev/null || echo 'CONSUMER_API_URL=http://api:3001/v1' >> .env.production && \
  grep -q '^PAYER_WEB_URL=' .env.production 2>/dev/null || echo 'PAYER_WEB_URL=${PUBLIC_PAYER_WEB_URL}' >> .env.production && \
  sed -i 's|^OPS_SITE_ADDRESS=.*|OPS_SITE_ADDRESS=${OPS_SITE_ADDRESS}|' .env.production && \
  sed -i 's|^OPS_CORS_ORIGIN=.*|OPS_CORS_ORIGIN=${PUBLIC_OPS_WEB_URL}|' .env.production && \
  sed -i 's|^DOCKER_OPS_API_IMAGE=.*|DOCKER_OPS_API_IMAGE=${OPS_API_IMAGE}|' .env.production && \
  sed -i 's|^DOCKER_OPS_WEB_IMAGE=.*|DOCKER_OPS_WEB_IMAGE=${OPS_WEB_IMAGE}|' .env.production"

echo "==> Starting ops services + reloading Caddy"
"${SSH[@]}" "cd ${REMOTE_DIR} && docker compose --env-file .env.production up -d ops-api ops-web caddy"

echo "==> Seeding ops admin (idempotent)"
"${SSH[@]}" "cd ${REMOTE_DIR} && docker compose --env-file .env.production exec -T api sh -c 'cd /app/backend && npx --yes tsx prisma/seed-admin.ts'" || true

echo "==> Waiting for ops health"
for _ in $(seq 1 36); do
  login_code="$(curl -s -o /dev/null -w '%{http_code}' "https://${OPS_SITE_ADDRESS}/login" 2>/dev/null || echo '000')"
  api_code="$(curl -s -o /dev/null -w '%{http_code}' "https://${OPS_SITE_ADDRESS}/admin/v1/dashboard/kpis" 2>/dev/null || echo '000')"
  if [[ "$login_code" == "200" && "$api_code" == "401" ]]; then
    echo ""
    echo "Ops portal deployed successfully."
    echo "  UI:     https://${OPS_SITE_ADDRESS}"
    echo "  API:    https://${OPS_SITE_ADDRESS}/admin/v1"
    echo "  Login:  https://${OPS_SITE_ADDRESS}/login"
    echo "  SSH:    ssh -i ${SSH_KEY} root@${SERVER_IP}"
    exit 0
  fi
  if [[ $(( _ % 6 )) -eq 0 ]]; then
    echo "    (waiting — login=${login_code}, api=${api_code}; DNS A → ${SERVER_IP})"
  fi
  sleep 5
done

echo "Ops health check timed out. Logs:" >&2
"${SSH[@]}" "cd ${REMOTE_DIR} && docker compose --env-file .env.production ps ops-api ops-web caddy && docker compose --env-file .env.production logs --tail=80 ops-api ops-web caddy" >&2
exit 1
