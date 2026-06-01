#!/usr/bin/env bash
# Payspin mobile release serial bumping.
#
# Serial format: V{major}.{minor}{letter}  e.g. V1.6a → V1.6b → … → V1.6z → V1.7a
# Syncs mobile/lib/core/config/app_version.dart and pubspec.yaml (semver + build number).
#
# Usage:
#   ./scripts/dev/bump-mobile-version.sh current          # print current serial
#   ./scripts/dev/bump-mobile-version.sh set V1.6a      # pin serial (resets letter line)
#   ./scripts/dev/bump-mobile-version.sh next           # increment for the next build
#   ./scripts/dev/bump-mobile-version.sh sync-from-dist # take max(serial in dist, dart)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION_DART="$ROOT/mobile/lib/core/config/app_version.dart"
PUBSPEC="$ROOT/mobile/pubspec.yaml"
DIST="$ROOT/mobile/dist"

read_serial_from_dart() {
  grep "static const String serial" "$VERSION_DART" | sed -E "s/.*serial = '([^']+)'.*/\1/"
}

read_build_number_from_dart() {
  grep "static const int buildNumber" "$VERSION_DART" | sed -E 's/.*buildNumber = ([0-9]+).*/\1/'
}

parse_serial() {
  local serial="$1"
  if [[ ! "$serial" =~ ^V([0-9]+)\.([0-9]+)([a-z])$ ]]; then
    echo "Invalid serial '$serial' — expected V1.6a format" >&2
    return 1
  fi
  SERIAL_MAJOR="${BASH_REMATCH[1]}"
  SERIAL_MINOR="${BASH_REMATCH[2]}"
  SERIAL_LETTER="${BASH_REMATCH[3]}"
}

serial_to_sort_key() {
  local serial="$1"
  parse_serial "$serial"
  printf '%04d-%04d-%02d' "$SERIAL_MAJOR" "$SERIAL_MINOR" "$(( $(printf '%d' "'$SERIAL_LETTER") - 97 ))"
}

max_serial() {
  local best="${1:-}"
  local candidate
  for candidate in "$@"; do
    [[ -z "$candidate" ]] && continue
    if [[ -z "$best" ]] || [[ "$(serial_to_sort_key "$candidate")" > "$(serial_to_sort_key "$best")" ]]; then
      best="$candidate"
    fi
  done
  echo "$best"
}

highest_serial_in_dist() {
  local f base serial best=""
  shopt -s nullglob
  for f in "$DIST"/payspin-V*-release.apk "$DIST"/payspin-V*-release.ipa; do
    base="$(basename "$f")"
    if [[ "$base" =~ payspin-(V[0-9]+\.[0-9]+[a-z])-release\.(apk|ipa) ]]; then
      serial="${BASH_REMATCH[1]}"
      best="$(max_serial "$best" "$serial")"
    fi
  done
  shopt -u nullglob
  echo "$best"
}

increment_serial() {
  local serial="$1"
  parse_serial "$serial"
  local letters="abcdefghijklmnopqrstuvwxyz"
  local idx=$(( $(printf '%d' "'$SERIAL_LETTER") - 97 ))
  if (( idx < 25 )); then
    SERIAL_LETTER="${letters:idx+1:1}"
  else
    SERIAL_MINOR=$(( SERIAL_MINOR + 1 ))
    SERIAL_LETTER="a"
  fi
  echo "V${SERIAL_MAJOR}.${SERIAL_MINOR}${SERIAL_LETTER}"
}

write_version_files() {
  local serial="$1"
  local build_number="$2"
  parse_serial "$serial"
  local semver="${SERIAL_MAJOR}.${SERIAL_MINOR}.0"

  sed -i '' "s/static const String serial = '[^']*'/static const String serial = '$serial'/" "$VERSION_DART"
  sed -i '' "s/static const String semver = '[^']*'/static const String semver = '$semver'/" "$VERSION_DART"
  sed -i '' "s/static const int buildNumber = [0-9]*/static const int buildNumber = $build_number/" "$VERSION_DART"

  sed -i '' "s/^version: .*/version: ${semver}+${build_number}/" "$PUBSPEC"
}

cmd="${1:-current}"
case "$cmd" in
  current)
    read_serial_from_dart
    ;;
  set)
    serial="${2:?Usage: bump-mobile-version.sh set V1.6a}"
    parse_serial "$serial"
    build_number="$(read_build_number_from_dart)"
    write_version_files "$serial" "$build_number"
    echo "$serial"
    ;;
  next)
    current="$(read_serial_from_dart)"
    dist_high="$(highest_serial_in_dist)"
    base="$(max_serial "$current" "$dist_high")"
    next="$(increment_serial "$base")"
    build_number=$(( $(read_build_number_from_dart) + 1 ))
    write_version_files "$next" "$build_number"
    echo "$next"
    ;;
  sync-from-dist)
    current="$(read_serial_from_dart)"
    dist_high="$(highest_serial_in_dist)"
    best="$(max_serial "$current" "$dist_high")"
    if [[ "$best" != "$current" ]]; then
      build_number=$(( $(read_build_number_from_dart) + 1 ))
      write_version_files "$best" "$build_number"
    fi
    echo "$(read_serial_from_dart)"
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    exit 1
    ;;
esac
