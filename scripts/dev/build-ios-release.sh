#!/usr/bin/env bash
# Build a release IPA into mobile/dist with the same serial/manifest pattern as Android.
#
# Requires a one-time Xcode signing setup (see preflight below).
# Env: API_URL, SKIP_BUMP=1
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/mobile"
DIST="$MOBILE/dist"
BUMP="$ROOT/scripts/dev/bump-mobile-version.sh"
EXPORT_PLIST="$MOBILE/ios/ExportOptions.plist"
TEAM_ID="5HNF7DY6G7"
BUNDLE_ID="payspin.app"

API_URL="${API_URL:-https://pay.payspin.io/v1}"

RELEASE_ID="$("$BUMP" current)"
BUILD_NUM="$(grep "static const int buildNumber" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E 's/.*buildNumber = ([0-9]+).*/\1/')"
SEMVER="$(grep "static const String semver" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E "s/.*semver = '([^']+)'.*/\1/")"

preflight() {
  echo "==> Preflight: iOS code signing"
  if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Xcode is not installed." >&2
    exit 1
  fi

  if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "$TEAM_ID\|Moustafa\|payspin"; then
    cat <<EOF >&2

No Apple Development certificate found for Payspin team ($TEAM_ID).

One-time fix (≈2 min):
  1. open $MOBILE/ios/Runner.xcworkspace
  2. Xcode → Settings → Accounts → payspin.app@gmail.com (team Moustafa ALHAROON)
  3. Manage Certificates… → + → Apple Development
  4. Runner target → Signing & Capabilities → Team: Moustafa ALHAROON, Automatically manage signing ✓
  5. Product → Build (⌘B) once — Xcode downloads a fresh profile for $BUNDLE_ID

Then re-run: ./scripts/dev/build-ios-release.sh

EOF
    exit 1
  fi
  echo "    Signing identity OK"
}

echo "==> Building Payspin iOS $RELEASE_ID (store: $SEMVER+$BUILD_NUM)"
echo "    API_URL=$API_URL"
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

OUT="$DIST/payspin-${RELEASE_ID}-release.ipa"
cp "$IPA_SRC" "$OUT"
ln -sf "$(basename "$OUT")" "$DIST/payspin-latest-release.ipa"

SHA256="$(shasum -a 256 "$OUT" | awk '{print $1}')"
BUILT_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SIZE_BYTES="$(stat -f%z "$OUT" 2>/dev/null || stat -c%s "$OUT")"
MANIFEST="$DIST/manifest.json"

python3 - <<PY
import json, os
manifest_path = "$MANIFEST"
entry = {
    "releaseId": "$RELEASE_ID",
    "semver": "$SEMVER",
    "buildNumber": int("$BUILD_NUM"),
    "platform": "ios",
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
    if prev and (prev.get("releaseId") != entry["releaseId"] or prev.get("platform") != entry["platform"]):
        hist.insert(0, prev)
    data["history"] = hist[:20]
data["latest"] = entry
with open(manifest_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

if [[ "${SKIP_BUMP:-0}" != "1" ]]; then
  NEXT="$("$BUMP" next)"
  echo "==> Next release id: $NEXT"
fi

echo ""
echo "Built: $OUT"
echo "Latest: $DIST/payspin-latest-release.ipa → $(basename "$OUT")"
ls -lh "$OUT"
