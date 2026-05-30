#!/usr/bin/env bash
# Usage: ./scripts/dev/yapily-env-from-keys.sh <APPLICATION_ID> <APPLICATION_SECRET> [WEBHOOK_SECRET]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="$ROOT/backend/.env"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <YAPILY_APP_KEY> <YAPILY_APP_SECRET> [YAPILY_WEBHOOK_SECRET]"
  exit 1
fi

APP_KEY="$1"
APP_SECRET="$2"
WEBHOOK_SECRET="${3:-}"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ROOT/backend/.env.example" "$ENV_FILE"
fi

patch_var() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i '' "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_FILE"
  else
    echo "${key}=\"${val}\"" >> "$ENV_FILE"
  fi
}

patch_var YAPILY_APP_KEY "$APP_KEY"
patch_var YAPILY_APP_SECRET "$APP_SECRET"
if [[ -n "$WEBHOOK_SECRET" ]]; then
  patch_var YAPILY_WEBHOOK_SECRET "$WEBHOOK_SECRET"
fi
patch_var YAPILY_DEFAULT_INSTITUTION "yapily-mock"
patch_var YAPILY_DEFAULT_COUNTRY "NL"

echo "Updated $ENV_FILE (Yapily keys). Restart: pnpm --filter @payspin/backend dev"
