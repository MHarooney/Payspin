#!/usr/bin/env bash
# Build a release APK into mobile/dist with semver + build number.
#
# Each run:
#   1. Uses the version in app_version.dart / pubspec.yaml for this build
#   2. Writes payspin-{semver}-build{N}-release.apk + latest symlink + manifest.json
#   3. Bumps build number for the *next* upload
#
# Store mapping: semver → versionName, build number → versionCode (via pubspec).
#
# Env:
#   API_URL          — backend base (default prod)
#   SKIP_BUMP=1      — do not bump after build (CI pin builds)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/mobile"
DIST="$MOBILE/dist"
BUMP="$ROOT/scripts/dev/bump-mobile-version.sh"

API_URL="${API_URL:-https://pay.payspin.io/v1}"

# integration_test is dev-only; strip it if a prior debug build left it in the registrant.
sanitize_android_plugins() {
  local registrant="$MOBILE/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
  [[ -f "$registrant" ]] || return 0
  grep -q integration_test "$registrant" || return 0
  REGISTRANT_PATH="$registrant" python3 - <<'PY'
import os, re
from pathlib import Path
path = Path(os.environ["REGISTRANT_PATH"])
text = path.read_text()
text = re.sub(
    r"\n\s*try \{\n"
    r"\s*flutterEngine\.getPlugins\(\)\.add\(new dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);\n"
    r"\s*\} catch \(Exception e\) \{\n"
    r'\s*Log\.e\(TAG, "Error registering plugin integration_test[^"]+", e\);\n'
    r"\s*\}",
    "",
    text,
)
path.write_text(text)
PY
}

RELEASE_ID="$("$BUMP" current)"
BUILD_NUM="$(grep "static const int buildNumber" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E 's/.*buildNumber = ([0-9]+).*/\1/')"
SEMVER="$(grep "static const String semver" "$MOBILE/lib/core/config/app_version.dart" \
  | sed -E "s/.*semver = '([^']+)'.*/\1/")"

echo "==> Building Payspin $RELEASE_ID (store: $SEMVER+$BUILD_NUM)"
echo "    API_URL=$API_URL"
sanitize_android_plugins
cd "$MOBILE"

flutter build apk --release --dart-define=API_URL="$API_URL"

mkdir -p "$DIST"
OUT="$DIST/payspin-${RELEASE_ID}-release.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$OUT"

# Stable alias for testers / scripts that always want the newest artifact.
ln -sf "$(basename "$OUT")" "$DIST/payspin-latest-release.apk"

SHA256="$(shasum -a 256 "$OUT" | awk '{print $1}')"
BUILT_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SIZE_BYTES="$(stat -f%z "$OUT" 2>/dev/null || stat -c%s "$OUT")"

# Append/update manifest — keeps dist self-describing for QA handoffs.
MANIFEST="$DIST/manifest.json"
python3 - <<PY
import json, os
manifest_path = "$MANIFEST"
entry = {
    "releaseId": "$RELEASE_ID",
    "semver": "$SEMVER",
    "buildNumber": int("$BUILD_NUM"),
    "platform": "android-apk",
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
    if data.get("latest") and data["latest"].get("releaseId") != entry["releaseId"]:
        hist.insert(0, data["latest"])
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
echo "Latest: $DIST/payspin-latest-release.apk → $(basename "$OUT")"
echo "Manifest: $MANIFEST"
ls -lh "$OUT"
