#!/usr/bin/env bash
# Build and push Payspin API image to Docker Hub (payspin account).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${DOCKER_IMAGE:-payspin/api}"
TAG="${DOCKER_TAG:-latest}"

cd "$ROOT"

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop." >&2
  exit 1
fi

echo "==> Building ${IMAGE}:${TAG}"
docker build -f backend/Dockerfile -t "${IMAGE}:${TAG}" .

echo "==> Pushing ${IMAGE}:${TAG}"
docker push "${IMAGE}:${TAG}"

echo "Done: ${IMAGE}:${TAG}"
