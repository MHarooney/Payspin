#!/usr/bin/env bash
# Run Payspin mobile on a physical iPhone (Payspin team 5HNF7DY6G7).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/mobile"
DEVICE_NAME="${1:-Mahmoud AlHaroon's iPhone}"
API_URL="${API_URL:-http://$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1):3001/v1}"

cd "$MOBILE"

DEVICE_ID="$(flutter devices 2>/dev/null | grep -F "$DEVICE_NAME" | head -1 | awk '{print $3}')"
if [[ -z "${DEVICE_ID:-}" ]]; then
  echo "Device not found: $DEVICE_NAME" >&2
  flutter devices
  exit 1
fi

echo "→ Device: $DEVICE_ID"
echo "→ API_URL: $API_URL"
echo "→ Team: 5HNF7DY6G7 (payspin.app)"
echo ""
echo "If signing fails: open ios/Runner.xcworkspace → Runner → Signing"
echo "  Sign in with payspin.app@gmail.com and remove broken mobile@innovito.me"
echo ""

exec flutter run -d "$DEVICE_ID" --dart-define=API_URL="$API_URL"
