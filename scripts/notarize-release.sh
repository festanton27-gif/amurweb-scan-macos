#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT/dist}"
META="$ROOT/Sources/AMURWEBScanMac/AppMetadata.swift"
VERSION="$(awk -F'"' '/static let version =/ { print $2; exit }' "$META")"
CHANNEL="$(awk -F'"' '/static let channel =/ { print $2; exit }' "$META")"
DMG="$OUT_DIR/AMURWEB-Scan-macOS-$VERSION-$CHANNEL-Universal.dmg"
PROFILE="${NOTARYTOOL_PROFILE:-}"

if [[ -z "$PROFILE" ]]; then
  echo "NOTARYTOOL_PROFILE is not set." >&2
  echo "Create a keychain profile with: xcrun notarytool store-credentials <profile>" >&2
  exit 1
fi

if [[ ! -f "$DMG" ]]; then
  echo "DMG not found: $DMG" >&2
  exit 1
fi

if ! codesign -dv --verbose=4 "$OUT_DIR/AMURWEB Scan.app" 2>&1 | grep -q "Authority=Developer ID Application"; then
  echo "The app is not signed with Developer ID Application. Refusing notarization." >&2
  exit 1
fi

xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl -a -t open --context context:primary-signature -v "$DMG"
shasum -a 256 "$DMG" > "$OUT_DIR/SHA256SUMS.txt"

echo "Notarization and stapling completed: $DMG"
