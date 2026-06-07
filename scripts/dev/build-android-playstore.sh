#!/usr/bin/env bash
# Build a Google Play release AAB and optionally upload to the Play Console.
#
# Prerequisites (one-time):
#   1. App created in Google Play Console for io.payspin.payspin_mobile (or your applicationId)
#   2. Service account with Play Console API access (Setup → API access)
#   3. JSON key at ~/.config/payspin/google-play-service-account.json (or set GOOGLE_PLAY_KEY)
#
# Usage:
#   ./scripts/dev/build-android-playstore.sh              # build AAB only
#   UPLOAD=1 ./scripts/dev/build-android-playstore.sh     # build + upload to internal track
#   TRACK=alpha UPLOAD=1 ./scripts/dev/build-android-playstore.sh
#
# Env: API_URL, SKIP_BUMP=1, SKIP_UPLOAD=1, UPLOAD=1, TRACK (internal|alpha|beta|production)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/mobile"
DIST="$MOBILE/dist"
BUMP="$ROOT/scripts/dev/bump-mobile-version.sh"
PACKAGE_NAME="${GOOGLE_PLAY_PACKAGE:-io.payspin.payspin_mobile}"
TRACK="${TRACK:-internal}"
GOOGLE_PLAY_KEY="${GOOGLE_PLAY_KEY:-$HOME/.config/payspin/google-play-service-account.json}"

API_URL="${API_URL:-https://pay.payspin.io/v1}"

RELEASE_ID="$("$BUMP" current)"
BUILD_NUM="$(grep "static const int buildNumber" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E 's/.*buildNumber = ([0-9]+).*/\1/')"
SEMVER="$(grep "static const String semver" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E "s/.*semver = '([^']+)'.*/\1/")"

upload_aab() {
  local aab="$1"
  if [[ ! -f "$GOOGLE_PLAY_KEY" ]]; then
    cat <<EOF

No Play Console upload key at:
  $GOOGLE_PLAY_KEY

One-time setup:
  1. Play Console → Setup → API access → Link Google Cloud project
  2. Create service account → Grant "Release to testing tracks" (or Admin)
  3. Download JSON key → save as $GOOGLE_PLAY_KEY

Manual upload:
  Play Console → Production / Testing → Create release → Upload App Bundle
  File: $aab
  Version name: $SEMVER   Version code: $BUILD_NUM

Or install fastlane and run:
  fastlane supply --aab "$aab" --track $TRACK --package_name $PACKAGE_NAME \\
    --json_key "$GOOGLE_PLAY_KEY" --skip_upload_metadata --skip_upload_images

EOF
    return 0
  fi

  if command -v fastlane >/dev/null 2>&1; then
    echo "==> Uploading to Google Play ($TRACK track) via fastlane…"
    fastlane supply \
      --aab "$aab" \
      --track "$TRACK" \
      --package_name "$PACKAGE_NAME" \
      --json_key "$GOOGLE_PLAY_KEY" \
      --skip_upload_metadata \
      --skip_upload_images \
      --skip_upload_screenshots
    echo ""
    echo "Upload submitted. Check Play Console → $TRACK testing."
    return 0
  fi

  cat <<EOF

fastlane not installed. Build succeeded; upload manually or:

  brew install fastlane
  UPLOAD=1 ./scripts/dev/build-android-playstore.sh

AAB ready: $aab
  Version name: $SEMVER
  Version code: $BUILD_NUM

EOF
}

should_upload() {
  [[ "${SKIP_UPLOAD:-0}" == "1" ]] && return 1
  [[ "${UPLOAD:-0}" == "1" ]]
}

echo "==> Building Payspin Play Store $RELEASE_ID (store: $SEMVER+$BUILD_NUM)"
echo "    API_URL=$API_URL"
echo "    Package: $PACKAGE_NAME"
cd "$MOBILE"

flutter build appbundle --release --dart-define=API_URL="$API_URL"

mkdir -p "$DIST"
AAB_SRC="$(find build/app/outputs/bundle -name '*.aab' -print -quit)"
if [[ -z "${AAB_SRC:-}" ]]; then
  echo "No .aab found under build/app/outputs/bundle" >&2
  exit 1
fi

OUT="$DIST/payspin-${RELEASE_ID}-release.aab"
cp "$AAB_SRC" "$OUT"
ln -sf "$(basename "$OUT")" "$DIST/payspin-latest-release.aab"

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
    "platform": "android-play",
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

echo ""
echo "Built: $OUT"
echo "Latest: $DIST/payspin-latest-release.aab → $(basename "$OUT")"
ls -lh "$OUT"

if should_upload; then
  upload_aab "$OUT"
else
  echo ""
  echo "Upload skipped (set UPLOAD=1 to upload via fastlane supply)."
fi

if [[ "${SKIP_BUMP:-0}" != "1" ]]; then
  NEXT="$("$BUMP" next)"
  echo "==> Next release id: $NEXT"
fi
