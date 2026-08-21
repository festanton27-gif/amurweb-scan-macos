#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT/dist}"
META="$ROOT/Sources/AMURWEBScanMac/AppMetadata.swift"
VERSION="$(awk -F'"' '/static let version =/ { print $2; exit }' "$META")"
CHANNEL="$(awk -F'"' '/static let channel =/ { print $2; exit }' "$META")"
APP_NAME="AMURWEB Scan"
APP="$OUT_DIR/$APP_NAME.app"
DMG="$OUT_DIR/AMURWEB-Scan-macOS-$VERSION-$CHANNEL-Universal.dmg"
GUIDE="$OUT_DIR/AMURWEB-Scan-macOS-$VERSION-Tester-Guide-RU.md"
SUMS="$OUT_DIR/SHA256SUMS.txt"

fail() {
  echo "RELEASE VERIFY FAILED: $*" >&2
  exit 1
}

[[ -n "$VERSION" ]] || fail "version is empty"
[[ -n "$CHANNEL" ]] || fail "channel is empty"
[[ -d "$APP" ]] || fail "app bundle missing: $APP"
[[ -f "$DMG" ]] || fail "DMG missing: $DMG"
[[ -f "$GUIDE" ]] || fail "tester guide missing: $GUIDE"
[[ -f "$SUMS" ]] || fail "SHA256SUMS.txt missing"

PLIST="$APP/Contents/Info.plist"
BIN="$APP/Contents/MacOS/$APP_NAME"
[[ -f "$PLIST" ]] || fail "Info.plist missing"
[[ -x "$BIN" ]] || fail "app executable missing or not executable"

plutil -lint "$PLIST" >/dev/null
BUNDLE_VERSION="$(plutil -extract CFBundleShortVersionString raw -o - "$PLIST")"
BUNDLE_BUILD="$(plutil -extract CFBundleVersion raw -o - "$PLIST")"
BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw -o - "$PLIST")"
MIN_OS="$(plutil -extract LSMinimumSystemVersion raw -o - "$PLIST")"

[[ "$BUNDLE_VERSION" == "$VERSION" ]] || fail "bundle version $BUNDLE_VERSION != AppMetadata $VERSION"
[[ "$BUNDLE_BUILD" =~ ^[0-9]+$ ]] || fail "CFBundleVersion must be numeric"
[[ "$BUNDLE_ID" == "ru.amurweb.scan" ]] || fail "unexpected bundle id: $BUNDLE_ID"
[[ "$MIN_OS" == "13.0" ]] || fail "unexpected minimum macOS: $MIN_OS"

ARCHS="$(lipo -archs "$BIN")"
[[ " $ARCHS " == *" arm64 "* ]] || fail "arm64 missing from Universal executable: $ARCHS"
[[ " $ARCHS " == *" x86_64 "* ]] || fail "x86_64 missing from Universal executable: $ARCHS"

codesign --verify --deep --strict "$APP"

EXPECTED_SHA="$(awk 'NR==1 {print $1}' "$SUMS")"
ACTUAL_SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"
[[ -n "$EXPECTED_SHA" ]] || fail "SHA256SUMS.txt has no digest"
[[ "$EXPECTED_SHA" == "$ACTUAL_SHA" ]] || fail "DMG SHA-256 mismatch"

grep -q "$VERSION" "$GUIDE" || fail "tester guide does not mention current version $VERSION"

MOUNT_DIR="$(mktemp -d /tmp/amurweb-scan-verify.XXXXXX)"
cleanup() {
  hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || true
  rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT_DIR" -quiet
MOUNT_APP="$MOUNT_DIR/$APP_NAME.app"
[[ -d "$MOUNT_APP" ]] || fail "app bundle missing inside DMG"
[[ -L "$MOUNT_DIR/Applications" ]] || fail "Applications symlink missing inside DMG"

MOUNT_PLIST="$MOUNT_APP/Contents/Info.plist"
MOUNT_BIN="$MOUNT_APP/Contents/MacOS/$APP_NAME"
[[ "$(plutil -extract CFBundleShortVersionString raw -o - "$MOUNT_PLIST")" == "$VERSION" ]] || fail "DMG app version mismatch"
MOUNT_ARCHS="$(lipo -archs "$MOUNT_BIN")"
[[ " $MOUNT_ARCHS " == *" arm64 "* && " $MOUNT_ARCHS " == *" x86_64 "* ]] || fail "DMG executable is not Universal: $MOUNT_ARCHS"
codesign --verify --deep --strict "$MOUNT_APP"

printf 'Release verification OK\n'
printf 'Version: %s %s\n' "$VERSION" "$CHANNEL"
printf 'Bundle build: %s\n' "$BUNDLE_BUILD"
printf 'Architectures: %s\n' "$ARCHS"
printf 'DMG SHA-256: %s\n' "$ACTUAL_SHA"
