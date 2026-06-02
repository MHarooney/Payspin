#!/usr/bin/env bash
# Run Payspin on the iOS Simulator (no Apple Developer membership required).
#
# Defaults to the production API so the simulator works without a local backend.
# For local API on the Mac host, pass:
#   API_URL=http://127.0.0.1:3001/v1 ./scripts/dev/ios-run-simulator.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/mobile"
DEVICE_NAME="${1:-iPhone 17 Pro}"
API_URL="${API_URL:-http://178.105.118.225/v1}"

cd "$MOBILE"

xcrun simctl boot "$DEVICE_NAME" 2>/dev/null || true
open -a Simulator 2>/dev/null || true

echo "→ Simulator: $DEVICE_NAME"
echo "→ API_URL: $API_URL"
echo ""

exec flutter run -d "$DEVICE_NAME" --dart-define=API_URL="$API_URL"
