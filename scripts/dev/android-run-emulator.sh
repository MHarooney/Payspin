#!/usr/bin/env bash
# Run Payspin on the Android emulator (Pixel_7_API_34).
set -euo pipefail

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API_URL="${API_URL:-http://10.0.2.2:3001/v1}"

if ! adb devices | grep -q 'emulator.*device'; then
  echo "→ Starting Pixel_7_API_34…"
  flutter emulators --launch Pixel_7_API_34
  adb wait-for-device
  while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
    sleep 2
  done
fi

DEVICE_ID="$(adb devices | awk '/emulator.*device$/{print $1; exit}')"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No Android emulator found. Run: flutter devices" >&2
  exit 1
fi

echo "→ Device: $DEVICE_ID"
echo "→ API_URL: $API_URL"
cd "$ROOT/mobile"
exec flutter run -d "$DEVICE_ID" --dart-define=API_URL="$API_URL"
