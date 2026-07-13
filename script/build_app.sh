#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/BuenaPostura.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build -c debug --product BuenaPostura

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$ROOT_DIR/.build/debug/BuenaPostura" "$MACOS_DIR/BuenaPostura"

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

echo "$APP_DIR"
