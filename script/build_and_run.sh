#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
APP_NAME="TeslaGarage"
BUNDLE_ID="com.kevinhowe.teslagarage"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_MACOS="$APP_BUNDLE/Contents/MacOS"
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
APP_FRAMEWORKS="$APP_BUNDLE/Contents/Frameworks"
SPARKLE_PUBLIC_KEY="1QwxGTbkRZRB2hZJ8wTAJwytcGxG1v5i9/l/oEVuPzg="
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-}"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
cd "$ROOT_DIR"
swift build
BUILD_DIR="$(swift build --show-bin-path)"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$APP_FRAMEWORKS"
cp "$BUILD_DIR/$APP_NAME" "$APP_MACOS/$APP_NAME"
# SwiftPM's Bundle.module accessor expects this exact generated resource bundle.
cp -R "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle" "$APP_RESOURCES/"
# Sparkle is supplied as a SwiftPM binary framework and must be embedded in the app bundle.
ditto "$BUILD_DIR/Sparkle.framework" "$APP_FRAMEWORKS/Sparkle.framework"
# Custom application icon and the original Icon Composer source document.
cp "$ROOT_DIR/Sources/TeslaGarage/Resources/TeslaGarageCustom.icns" "$APP_RESOURCES/"
cp -R "$ROOT_DIR/Sources/TeslaGarage/Resources/TeslaGarage.icon" "$APP_RESOURCES/"
chmod +x "$APP_MACOS/$APP_NAME"
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>$APP_NAME</string><key>CFBundleIdentifier</key><string>$BUNDLE_ID</string><key>CFBundleName</key><string>$APP_NAME</string><key>CFBundleIconFile</key><string>TeslaGarageCustom.icns</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>0.1.0</string><key>CFBundleVersion</key><string>1</string><key>LSMinimumSystemVersion</key><string>14.0</string><key>NSPrincipalClass</key><string>NSApplication</string><key>SUEnableAutomaticChecks</key><false/><key>SUPublicEDKey</key><string>$SPARKLE_PUBLIC_KEY</string></dict></plist>
PLIST
if [[ -n "$SPARKLE_FEED_URL" ]]; then
  /usr/libexec/PlistBuddy -c "Add :SUFeedURL string $SPARKLE_FEED_URL" "$APP_BUNDLE/Contents/Info.plist"
fi
# Resource metadata copied from Finder must not be included in an ad-hoc signature.
xattr -cr "$APP_BUNDLE"
/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
case "$MODE" in
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
  --verify|verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 1; pgrep -x "$APP_NAME" >/dev/null ;;
  --debug|debug) lldb -- "$APP_MACOS/$APP_NAME" ;;
  --logs|logs) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\"" ;;
  --telemetry|telemetry) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\"" ;;
  *) exit 2 ;;
esac
