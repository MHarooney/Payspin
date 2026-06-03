#!/usr/bin/env bash
# Run Payspin mobile on a physical iPhone (Payspin team 5HNF7DY6G7).
#
# Usage (from repo root):
#   ./scripts/dev/ios-run-iphone.sh
#   ./scripts/dev/ios-run-iphone.sh "Mahmoud AlHaroon"
#   IOS_DEVICE_UDID=00008110-00060C6C3A83401E ./scripts/dev/ios-run-iphone.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/mobile"
DEVICE_NAME="${1:-Mahmoud AlHaroon}"
DEVICE_UDID="${IOS_DEVICE_UDID:-00008110-00060C6C3A83401E}"
API_URL="${API_URL:-https://pay.payspin.io/v1}"
DEVICE_TIMEOUT="${DEVICE_TIMEOUT:-15}"

cd "$MOBILE"

resolve_device_id() {
  if [[ -n "${IOS_DEVICE_UDID:-}" ]]; then
    echo "$IOS_DEVICE_UDID"
    return
  fi
  flutter devices --device-timeout "$DEVICE_TIMEOUT" 2>/dev/null \
    | awk -F'•' -v name="$DEVICE_NAME" '$0 ~ name {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}'
}

DEVICE_ID="$(resolve_device_id)"
if [[ -z "${DEVICE_ID:-}" ]]; then
  echo "Device not found: $DEVICE_NAME (set IOS_DEVICE_UDID to override)" >&2
  flutter devices --device-timeout "$DEVICE_TIMEOUT"
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
