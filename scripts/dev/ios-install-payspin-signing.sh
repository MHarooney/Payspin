#!/usr/bin/env bash
# Install Payspin iOS signing assets (profile + development certificate).
#
# Prerequisites (Apple Developer → payspin.app@gmail.com / team 5HNF7DY6G7):
#   1. Payspin_Development_2026.mobileprovision (already created)
#   2. PayspinDevCert.csr uploaded → download Apple Development .cer for this Mac
#
# Usage:
#   ./scripts/dev/ios-install-payspin-signing.sh \
#     ~/Downloads/my-signature_files/Payspin_Development_2026.mobileprovision \
#     ~/Downloads/development.cer \
#     ~/Downloads/my-signature_files/PayspinDevCert.key
set -euo pipefail

PROFILE="${1:?mobileprovision path required}"
CER="${2:?Apple Development .cer path required}"
KEY="${3:-$HOME/Downloads/my-signature_files/PayspinDevCert.key}"

if [[ ! -f "$PROFILE" ]]; then echo "Missing profile: $PROFILE" >&2; exit 1; fi
if [[ ! -f "$CER" ]]; then echo "Missing certificate: $CER" >&2; exit 1; fi
if [[ ! -f "$KEY" ]]; then echo "Missing private key: $KEY" >&2; exit 1; fi

UUID=$(security cms -D -i "$PROFILE" 2>/dev/null | plutil -extract UUID raw -)
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
mkdir -p ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles
cp "$PROFILE" ~/Library/MobileDevice/Provisioning\ Profiles/"$UUID.mobileprovision"
cp "$PROFILE" ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/"$UUID.mobileprovision"

security import "$CER" -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null || true
security import "$KEY" -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null || true

echo "✓ Profile installed ($UUID)"
echo "✓ Certificate + key imported to login keychain"
echo ""
security find-identity -v -p codesigning | grep -i "Apple Development" || true
echo ""
echo "If the profile was created before this certificate, regenerate it on"
echo "https://developer.apple.com/account/resources/profiles/list (include this Mac cert)."
