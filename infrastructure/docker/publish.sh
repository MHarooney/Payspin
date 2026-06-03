#!/usr/bin/env bash
# Build (linux/amd64) and push Payspin images to Docker Hub (payspin account).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API_IMAGE="${DOCKER_IMAGE:-payspin/api:latest}"
WEB_IMAGE="${DOCKER_WEB_IMAGE:-payspin/web:latest}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://localhost/v1}"

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop." >&2
  exit 1
fi

# Optional: pause other local Docker stacks before a heavy build.
# Set EVOLMS_PRE_BUILD=0 to skip (e.g. when the hook hangs).
if [[ -z "${EVOLMS_PRE_BUILD+set}" ]]; then
  EVOLMS_PRE_BUILD="${HOME}/Desktop/evo-lms/scripts/lib/pre-docker-build.sh"
fi
if [[ -n "$EVOLMS_PRE_BUILD" && "$EVOLMS_PRE_BUILD" != "0" && -f "$EVOLMS_PRE_BUILD" ]]; then
  # shellcheck source=/dev/null
  source "$EVOLMS_PRE_BUILD"
  pre_docker_build_pause
  trap pre_docker_build_restore EXIT
fi

cd "$ROOT"

echo "==> Building ${API_IMAGE} (${DOCKER_PLATFORM})"
docker build --platform "$DOCKER_PLATFORM" -f backend/Dockerfile -t "$API_IMAGE" .

echo "==> Building ${WEB_IMAGE} (NEXT_PUBLIC_API_URL=${PUBLIC_API_URL}, ${DOCKER_PLATFORM})"
docker build --platform "$DOCKER_PLATFORM" -f frontend/Dockerfile \
  --build-arg "NEXT_PUBLIC_API_URL=${PUBLIC_API_URL}" \
  -t "$WEB_IMAGE" .

echo "==> Pushing ${API_IMAGE}"
docker push "$API_IMAGE"

echo "==> Pushing ${WEB_IMAGE}"
docker push "$WEB_IMAGE"

echo "Done:"
echo "  ${API_IMAGE}"
echo "  ${WEB_IMAGE}"
