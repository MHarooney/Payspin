#!/usr/bin/env bash
# Build an App Store / TestFlight IPA and optionally upload via CLI.
#
# Prerequisites (one-time):
#   1. App record in App Store Connect for bundle id payspin.app
#   2. Xcode → Accounts → payspin.app@gmail.com → Apple Distribution certificate
#   3. App-specific password for upload (appleid.apple.com) stored as:
#        export APPLE_UPLOAD_PASSWORD='xxxx-xxxx-xxxx-xxxx'
#      or in Keychain: security add-generic-password -a payspin.app@gmail.com \
#        -s AC_PASSWORD -w 'xxxx-xxxx-xxxx-xxxx'
#
# Usage (from repo root):
#   ./scripts/dev/build-ios-testflight.sh              # build + upload if password set
#   SKIP_UPLOAD=1 ./scripts/dev/build-ios-testflight.sh   # build only
#   UPLOAD=1 APPLE_UPLOAD_PASSWORD=... ./scripts/dev/build-ios-testflight.sh
#
# Env: API_URL, SKIP_BUMP=1, SKIP_UPLOAD=1, UPLOAD=1, APPLE_ID, APPLE_UPLOAD_PASSWORD
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/mobile"
DIST="$MOBILE/dist"
BUMP="$ROOT/scripts/dev/bump-mobile-version.sh"
EXPORT_PLIST="$MOBILE/ios/ExportOptions-appstore.plist"
TEAM_ID="5HNF7DY6G7"
BUNDLE_ID="payspin.app"
APPLE_ID="${APPLE_ID:-payspin.app@gmail.com}"

API_URL="${API_URL:-https://pay.payspin.io/v1}"

SERIAL="$("$BUMP" current)"
BUILD_NUM="$(grep "static const int buildNumber" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E 's/.*buildNumber = ([0-9]+).*/\1/')"
SEMVER="$(grep "static const String semver" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E "s/.*semver = '([^']+)'.*/\1/")"

resolve_upload_password() {
  if [[ -n "${APPLE_UPLOAD_PASSWORD:-}" ]]; then
    echo "$APPLE_UPLOAD_PASSWORD"
    return
  fi
  if security find-generic-password -a "$APPLE_ID" -s AC_PASSWORD -w 2>/dev/null; then
    return
  fi
  return 1
}

preflight() {
  echo "==> Preflight: iOS TestFlight signing"
  if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Xcode is not installed." >&2
    exit 1
  fi

  if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Distribution"; then
    cat <<EOF >&2

No Apple Distribution certificate found for team $TEAM_ID.

One-time fix:
  1. open $MOBILE/ios/Runner.xcworkspace
  2. Xcode → Settings → Accounts → $APPLE_ID
  3. Manage Certificates… → + → Apple Distribution
  4. Runner target → Signing → Team: Moustafa ALHAROON, Automatically manage signing ✓
  5. Product → Archive once (or re-run this script)

EOF
    exit 1
  fi
  echo "    Apple Distribution certificate OK"
}

upload_ipa() {
  local ipa="$1"

  if [[ -n "${ASC_API_KEY_ID:-}" && -n "${ASC_API_ISSUER_ID:-}" && -n "${ASC_API_KEY_PATH:-}" ]]; then
    echo "==> Uploading to App Store Connect (API key)…"
    xcrun altool --upload-app \
      --type ios \
      --file "$ipa" \
      --apiKey "$ASC_API_KEY_ID" \
      --apiIssuer "$ASC_API_ISSUER_ID" \
      --apiKeyPath "$ASC_API_KEY_PATH"
    echo ""
    echo "Upload submitted. Check App Store Connect → TestFlight in ~5–15 min."
    return 0
  fi

  local password
  if ! password="$(resolve_upload_password)"; then
    cat <<EOF

No upload credentials. Build succeeded; skipping TestFlight upload.

Option A — app-specific password (appleid.apple.com → Sign-In and Security):
  security add-generic-password -a $APPLE_ID -s AC_PASSWORD -w 'xxxx-xxxx-xxxx-xxxx'
  UPLOAD=1 ./scripts/dev/build-ios-testflight.sh

Option B — App Store Connect API key (Users and Access → Integrations → App Store Connect API):
  # Existing Payspin team key (if you still have the .p8 from creation):
  export ASC_API_KEY_ID='6WPB5APML2'
  export ASC_API_ISSUER_ID='ae34543a-11bd-495f-902f-fc25c675d865'
  export ASC_API_KEY_PATH="\$HOME/.appstoreconnect/AuthKey_6WPB5APML2.p8"
  UPLOAD=1 ./scripts/dev/build-ios-testflight.sh
  # Apple only lets you download the .p8 once — regenerate a new key if missing.

Manual upload:
  open -a Transporter
  # drag $ipa into Transporter

EOF
    return 0
  fi

  echo "==> Uploading to App Store Connect (TestFlight)…"
  xcrun altool --upload-app \
    --type ios \
    --file "$ipa" \
    --username "$APPLE_ID" \
    --password "$password"
  echo ""
  echo "Upload submitted. Processing usually takes 5–15 minutes."
  echo "  App Store Connect → TestFlight → $BUNDLE_ID"
  echo "  External testers: add emails under TestFlight → External Testing"
}

should_upload() {
  [[ "${SKIP_UPLOAD:-0}" == "1" ]] && return 1
  [[ "${UPLOAD:-0}" == "1" ]] && return 0
  if [[ -n "${ASC_API_KEY_ID:-}" && -n "${ASC_API_ISSUER_ID:-}" && -n "${ASC_API_KEY_PATH:-}" ]]; then
    return 0
  fi
  resolve_upload_password >/dev/null 2>&1
}

echo "==> Building Payspin TestFlight $SERIAL ($SEMVER+$BUILD_NUM)"
echo "    API_URL=$API_URL"
echo "    Export: app-store (TestFlight)"
preflight
echo ""

cd "$MOBILE"

flutter build ipa \
  --release \
  --dart-define=API_URL="$API_URL" \
  --export-options-plist="$EXPORT_PLIST"

mkdir -p "$DIST"
IPA_SRC="$(find build/ios/ipa -name '*.ipa' -print -quit)"
if [[ -z "${IPA_SRC:-}" ]]; then
  echo "No .ipa found under build/ios/ipa" >&2
  exit 1
fi

OUT="$DIST/payspin-${SERIAL}-testflight.ipa"
cp "$IPA_SRC" "$OUT"
ln -sf "$(basename "$OUT")" "$DIST/payspin-latest-testflight.ipa"

SHA256="$(shasum -a 256 "$OUT" | awk '{print $1}')"
BUILT_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SIZE_BYTES="$(stat -f%z "$OUT" 2>/dev/null || stat -c%s "$OUT")"
MANIFEST="$DIST/manifest.json"

python3 - <<PY
import json, os
manifest_path = "$MANIFEST"
entry = {
    "serial": "$SERIAL",
    "semver": "$SEMVER",
    "buildNumber": int("$BUILD_NUM"),
    "platform": "ios-testflight",
    "artifact": os.path.basename("$OUT"),
    "apiUrl": "$API_URL",
    "sha256": "$SHA256",
    "sizeBytes": int("$SIZE_BYTES"),
    "builtAt": "$BUILT_AT",
}
data = {"latest": entry, "history": []}
if os.path.isfile(manifest_path):
    with open(manifest_path) as f:
        data = json.load(f)
    hist = data.get("history") or []
    prev = data.get("latest")
    if prev and (prev.get("serial") != entry["serial"] or prev.get("platform") != entry["platform"]):
        hist.insert(0, prev)
    data["history"] = hist[:20]
data["latest"] = entry
with open(manifest_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

echo ""
echo "Built: $OUT"
echo "Latest: $DIST/payspin-latest-testflight.ipa → $(basename "$OUT")"
ls -lh "$OUT"

if should_upload; then
  upload_ipa "$OUT"
else
  echo ""
  echo "Upload skipped (set APPLE_UPLOAD_PASSWORD or UPLOAD=1 to upload via CLI)."
fi

if [[ "${SKIP_BUMP:-0}" != "1" ]]; then
  NEXT="$("$BUMP" next)"
  echo "==> Next build serial: $NEXT"
fi
