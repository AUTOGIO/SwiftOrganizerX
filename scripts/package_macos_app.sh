#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SwiftOrganizerX"
VERSION="${1:-${VERSION:-1.0.0}}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUNDLE_ID="${BUNDLE_ID:-com.autogio.SwiftOrganizerX}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}-macos.zip"

cd "$ROOT_DIR"

echo "Building ${APP_NAME} ${VERSION} (${BUILD_NUMBER})..."
swift build -c release

BINARY_PATH="$(find "$ROOT_DIR/.build" -path "*/release/${APP_NAME}" -type f | head -n 1)"

if [[ -z "$BINARY_PATH" ]]; then
  echo "Release binary not found." >&2
  exit 1
fi

rm -rf "$APP_BUNDLE" "$ZIP_PATH"
mkdir -p "$MACOS_DIR"

cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>SwiftOrganizerX uses Apple Events to read and organize your Notes in the Notes app.</string>
</dict>
</plist>
EOF

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE"
fi

plutil -lint "$CONTENTS_DIR/Info.plist" >/dev/null
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "Created app bundle: $APP_BUNDLE"
echo "Created zip archive: $ZIP_PATH"
