#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${CONFIGURATION:-release}"
INSTALL=0
OPEN_APP=0

for arg in "$@"; do
  case "$arg" in
    --debug)
      CONFIGURATION="debug"
      ;;
    --install)
      INSTALL=1
      ;;
    --open)
      INSTALL=1
      OPEN_APP=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

swift build -c "$CONFIGURATION"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_DIR="$ROOT/.build/app/RemoteAI.app"
CONTENTS="$APP_DIR/Contents"
ICON_SOURCE="$ROOT/.build/AppIcon-1024.png"
ICONSET="$ROOT/.build/AppIcon.iconset"
ICNS="$ROOT/.build/AppIcon.icns"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN_DIR/RemoteAI" "$CONTENTS/MacOS/RemoteAI"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

if [[ -n "${APP_VERSION:-}" ]]; then
  plutil -replace CFBundleShortVersionString -string "$APP_VERSION" "$CONTENTS/Info.plist"
fi
if [[ -n "${BUILD_NUMBER:-}" ]]; then
  plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$CONTENTS/Info.plist"
fi

swift "$ROOT/scripts/generate-app-icon.swift" "$ICON_SOURCE" >/dev/null
rm -rf "$ICONSET" "$ICNS"
mkdir -p "$ICONSET"

sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$ICON_SOURCE" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$ICNS"
cp "$ICNS" "$CONTENTS/Resources/AppIcon.icns"

SIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
if command -v codesign >/dev/null 2>&1; then
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --deep --sign - "$APP_DIR"
  else
    codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
  fi
  codesign --verify --deep --strict "$APP_DIR"
fi

if [[ "$INSTALL" == "1" ]]; then
  mkdir -p "$HOME/Applications"
  rm -rf "$HOME/Applications/RemoteAI.app"
  cp -R "$APP_DIR" "$HOME/Applications/RemoteAI.app"
  APP_PATH="$HOME/Applications/RemoteAI.app"
else
  APP_PATH="$APP_DIR"
fi

if [[ "$OPEN_APP" == "1" ]]; then
  open "$APP_PATH"
fi

echo "$APP_PATH"
