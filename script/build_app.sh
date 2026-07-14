#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/BuenaPostura.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
APP_DIR="$WORK_DIR/BuenaPostura.app"
DMG_ROOT="$WORK_DIR/dmg-root"
DMG_PATH="$ROOT_DIR/BuenaPostura.dmg"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build -c release --product BuenaPostura

mkdir -p "$MACOS_DIR"
cp "$ROOT_DIR/.build/release/BuenaPostura" "$MACOS_DIR/BuenaPostura"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BuenaPostura</string>
    <key>CFBundleIdentifier</key>
    <string>app.buenapostura.BuenaPostura</string>
    <key>CFBundleName</key>
    <string>BuenaPostura</string>
    <key>CFBundleDisplayName</key>
    <string>BuenaPostura</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMotionUsageDescription</key>
    <string>BuenaPostura usa el movimiento de tus AirPods para estimar tu postura. Los datos se procesan localmente.</string>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"
xattr -cr "$APP_DIR"
codesign --force --sign - "$APP_DIR" >/dev/null
codesign --verify --deep --strict "$APP_DIR"

rm -rf "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/BuenaPostura.app"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create -quiet -volname "BuenaPostura" -srcfolder "$DMG_ROOT" -ov -format UDZO "$DMG_PATH"

echo "$DMG_PATH"
