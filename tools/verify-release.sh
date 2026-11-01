#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:?usage: verify-release.sh <RemoteAI.app> <screenshots-dir> [expected-version]}"
SHOTS_DIR="${2:?usage: verify-release.sh <RemoteAI.app> <screenshots-dir> [expected-version]}"
EXPECTED_VERSION="${3:-}"
PLIST="$APP_DIR/Contents/Info.plist"
EXECUTABLE="$APP_DIR/Contents/MacOS/RemoteAI"
ICON="$APP_DIR/Contents/Resources/AppIcon.icns"

fail() {
  echo "VERIFY FAIL: $*" >&2
  exit 1
}

[[ -d "$APP_DIR" ]] || fail "app bundle is missing: $APP_DIR"
[[ -f "$PLIST" ]] || fail "Info.plist is missing"
[[ -x "$EXECUTABLE" ]] || fail "RemoteAI executable is missing or not executable"
[[ -s "$ICON" ]] || fail "AppIcon.icns is missing or empty"

BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw "$PLIST")"
[[ "$BUNDLE_ID" == "app.remoteai.mascot" ]] || fail "unexpected bundle id: $BUNDLE_ID"

MINIMUM="$(plutil -extract LSMinimumSystemVersion raw "$PLIST")"
[[ "$MINIMUM" == "14.0" ]] || fail "unexpected minimum macOS version: $MINIMUM"

UI_ELEMENT="$(plutil -extract LSUIElement raw "$PLIST")"
[[ "$UI_ELEMENT" == "true" ]] || fail "LSUIElement must remain true"

VERSION="$(plutil -extract CFBundleShortVersionString raw "$PLIST")"
if [[ -n "$EXPECTED_VERSION" && "$VERSION" != "$EXPECTED_VERSION" ]]; then
  fail "bundle version $VERSION does not match expected $EXPECTED_VERSION"
fi

codesign --verify --deep --strict "$APP_DIR" || fail "codesign verification failed"

ARCHS="$(/usr/bin/lipo -archs "$EXECUTABLE")"
[[ " $ARCHS " == *" arm64 "* ]] || fail "release binary is missing arm64: $ARCHS"
[[ " $ARCHS " == *" x86_64 "* ]] || fail "release binary is missing x86_64: $ARCHS"

[[ -d "$SHOTS_DIR" ]] || fail "screenshot directory is missing: $SHOTS_DIR"
COUNT="$(find "$SHOTS_DIR" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
[[ "$COUNT" -ge 16 ]] || fail "expected at least 16 PNG screenshots, found $COUNT"

required=(
  mascot-offline-light.png mascot-connecting-light.png mascot-syncing-light.png mascot-thinking-light.png mascot-waiting-light.png mascot-error-light.png
  mascot-offline-dark.png mascot-connecting-dark.png mascot-syncing-dark.png mascot-thinking-dark.png mascot-waiting-dark.png mascot-error-dark.png
  mascot-states-light.png mascot-states-dark.png settings-light.png settings-dark.png
)
for name in "${required[@]}"; do
  [[ -s "$SHOTS_DIR/$name" ]] || fail "missing release screenshot: $name"
done

for png in "$SHOTS_DIR"/*.png; do
  WIDTH="$(sips -g pixelWidth "$png" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
  HEIGHT="$(sips -g pixelHeight "$png" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
  [[ -n "$WIDTH" && -n "$HEIGHT" && "$WIDTH" -gt 0 && "$HEIGHT" -gt 0 ]] || fail "invalid PNG dimensions: $png"
done

echo "VERIFY PASS bundle=$BUNDLE_ID version=$VERSION archs=$ARCHS screenshots=$COUNT"
