#!/usr/bin/env bash
# Payspin mobile semver + monotonic build number.
#
# Flutter pubspec:  MAJOR.MINOR.PATCH+BUILD
#   PATCH line  → iOS CFBundleShortVersionString / Android versionName
#   BUILD       → iOS CFBundleVersion / Android versionCode (always increase)
#
# Dist artifacts: payspin-{semver}-build{BUILD}-release.{apk|ipa|aab}
#
# Usage:
#   ./scripts/dev/bump-mobile-version.sh current          # e.g. 0.9.0-build19
#   ./scripts/dev/bump-mobile-version.sh next             # +1 build (each upload)
#   ./scripts/dev/bump-mobile-version.sh set 0.9.0        # pin semver
#   ./scripts/dev/bump-mobile-version.sh set 0.9.0 25    # pin semver + build
#   ./scripts/dev/bump-mobile-version.sh patch          # 0.9.0 → 0.9.1 + build
#   ./scripts/dev/bump-mobile-version.sh minor          # 0.9.0 → 0.10.0 + build
#   ./scripts/dev/bump-mobile-version.sh major          # → 1.0.0 + build (launch)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION_DART="$ROOT/mobile/lib/core/config/app_version.dart"
PUBSPEC="$ROOT/mobile/pubspec.yaml"
DIST="$ROOT/mobile/dist"

read_semver_from_dart() {
  grep "static const String semver" "$VERSION_DART" | sed -E "s/.*semver = '([^']+)'.*/\1/"
}

read_build_number_from_dart() {
  grep "static const int buildNumber" "$VERSION_DART" | sed -E 's/.*buildNumber = ([0-9]+).*/\1/'
}

release_id() {
  echo "$(read_semver_from_dart)-build$(read_build_number_from_dart)"
}

parse_semver() {
  local semver="$1"
  if [[ ! "$semver" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Invalid semver '$semver' — expected MAJOR.MINOR.PATCH" >&2
    return 1
  fi
  VER_MAJOR="${BASH_REMATCH[1]}"
  VER_MINOR="${BASH_REMATCH[2]}"
  VER_PATCH="${BASH_REMATCH[3]}"
}

semver_to_sort_key() {
  parse_semver "$1"
  printf '%04d-%04d-%04d' "$VER_MAJOR" "$VER_MINOR" "$VER_PATCH"
}

parse_release_id() {
  local id="$1"
  if [[ ! "$id" =~ ^([0-9]+\.[0-9]+\.[0-9]+)-build([0-9]+)$ ]]; then
    return 1
  fi
  VER_PARSED_SEMVER="${BASH_REMATCH[1]}"
  VER_PARSED_BUILD="${BASH_REMATCH[2]}"
}

release_id_sort_key() {
  parse_release_id "$1"
  echo "$(semver_to_sort_key "$VER_PARSED_SEMVER")-$(printf '%06d' "$VER_PARSED_BUILD")"
}

max_release_id() {
  local best="${1:-}"
  local candidate
  for candidate in "$@"; do
    [[ -z "$candidate" ]] && continue
    if [[ -z "$best" ]] || [[ "$(release_id_sort_key "$candidate")" > "$(release_id_sort_key "$best")" ]]; then
      best="$candidate"
    fi
  done
  echo "$best"
}

highest_release_id_in_dist() {
  local f base id best=""
  shopt -s nullglob
  for f in "$DIST"/payspin-*-release.apk "$DIST"/payspin-*-release.ipa "$DIST"/payspin-*-release.aab "$DIST"/payspin-*-testflight.ipa; do
    base="$(basename "$f")"
    if [[ "$base" =~ payspin-([0-9]+\.[0-9]+\.[0-9]+-build[0-9]+)-(release|testflight)\.(apk|ipa|aab) ]]; then
      id="${BASH_REMATCH[1]}"
      best="$(max_release_id "$best" "$id")"
    fi
  done
  shopt -u nullglob
  echo "$best"
}

write_version_files() {
  local semver="$1"
  local build_number="$2"
  parse_semver "$semver"

  sed -i '' "s/static const String semver = '[^']*'/static const String semver = '$semver'/" "$VERSION_DART"
  sed -i '' "s/static const int buildNumber = [0-9]*/static const int buildNumber = $build_number/" "$VERSION_DART"
  sed -i '' "s/^version: .*/version: ${semver}+${build_number}/" "$PUBSPEC"
}

bump_semver() {
  local part="$1"
  local semver="$2"
  parse_semver "$semver"
  case "$part" in
    patch) VER_PATCH=$(( VER_PATCH + 1 )) ;;
    minor) VER_MINOR=$(( VER_MINOR + 1 )); VER_PATCH=0 ;;
    major) VER_MAJOR=$(( VER_MAJOR + 1 )); VER_MINOR=0; VER_PATCH=0 ;;
    *) echo "Unknown semver part: $part" >&2; return 1 ;;
  esac
  echo "${VER_MAJOR}.${VER_MINOR}.${VER_PATCH}"
}

cmd="${1:-current}"
case "$cmd" in
  current)
    release_id
    ;;
  set)
    semver="${2:?Usage: bump-mobile-version.sh set 0.9.0 [build]}"
    build_number="${3:-$(read_build_number_from_dart)}"
    write_version_files "$semver" "$build_number"
    release_id
    ;;
  next)
    current_id="$(release_id)"
    dist_high="$(highest_release_id_in_dist)"
    base="$(max_release_id "$current_id" "$dist_high")"
    if [[ -n "$base" && "$base" != "$current_id" ]]; then
      parse_release_id "$base"
      write_version_files "$VER_PARSED_SEMVER" "$(( VER_PARSED_BUILD + 1 ))"
    else
      write_version_files "$(read_semver_from_dart)" "$(( $(read_build_number_from_dart) + 1 ))"
    fi
    release_id
    ;;
  patch|minor|major)
    next_semver="$(bump_semver "$cmd" "$(read_semver_from_dart)")"
    write_version_files "$next_semver" "$(( $(read_build_number_from_dart) + 1 ))"
    release_id
    ;;
  sync-from-dist)
    current_id="$(release_id)"
    dist_high="$(highest_release_id_in_dist)"
    best="$(max_release_id "$current_id" "$dist_high")"
    if [[ -n "$best" && "$best" != "$current_id" ]]; then
      parse_release_id "$best"
      write_version_files "$VER_PARSED_SEMVER" "$(( VER_PARSED_BUILD + 1 ))"
    fi
    release_id
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    exit 1
    ;;
esac
