#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BINARY="${1:-$ROOT/build/AMURWEBScanMac}"
OUT_DIR="${2:-$ROOT/dist}"
META="$ROOT/Sources/AMURWEBScanMac/AppMetadata.swift"
VERSION="$(awk -F'"' '/static let version =/ { print $2; exit }' "$META")"
CHANNEL="$(awk -F'"' '/static let channel =/ { print $2; exit }' "$META")"
BUILD_NUMBER="10"
APP_NAME="AMURWEB Scan"
APP="$OUT_DIR/$APP_NAME.app"
DMG="$OUT_DIR/AMURWEB-Scan-macOS-$VERSION-$CHANNEL-Universal.dmg"
GUIDE="$OUT_DIR/AMURWEB-Scan-macOS-$VERSION-Tester-Guide-RU.md"

if [[ -z "$VERSION" || -z "$CHANNEL" ]]; then
  echo "Unable to read version/channel from AppMetadata.swift" >&2
  exit 1
fi

rm -rf "$OUT_DIR"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"
cp "$ROOT/assets/product-logo.png" "$APP/Contents/Resources/ProductLogo.png"
cp "$ROOT/assets/company-logo.png" "$APP/Contents/Resources/CompanyLogo.png"

ICONSET="$OUT_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
ICON_SRC="$ROOT/assets/product-icon.png"
for spec in "16:icon_16x16.png" "32:icon_16x16@2x.png" "32:icon_32x32.png" "64:icon_32x32@2x.png" "128:icon_128x128.png" "256:icon_128x128@2x.png" "256:icon_256x256.png" "512:icon_256x256@2x.png" "512:icon_512x512.png" "1024:icon_512x512@2x.png"; do
  size="${spec%%:*}"
  name="${spec#*:}"
  sips -z "$size" "$size" "$ICON_SRC" --out "$ICONSET/$name" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>ru.amurweb.scan</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Copyright © 2026 Amur Web Center (AMURWEB)</string>
</dict>
</plist>
PLIST

plutil -lint "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

STAGE="$OUT_DIR/dmg-stage"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"

rm -rf "$STAGE"
cp "$ROOT/TEST-CHECKLIST-RU.md" "$GUIDE"
shasum -a 256 "$DMG" > "$OUT_DIR/SHA256SUMS.txt"

echo "Created: $DMG"
echo "Tester guide: $GUIDE"
