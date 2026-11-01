#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${CONFIGURATION:-release}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$(cd "$ROOT" && swift build -c "$CONFIGURATION" --show-bin-path)"
APP_DIR="$ROOT/.build/app/RemoteAI.app"
CONTENTS="$APP_DIR/Contents"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN_DIR/RemoteAI" "$CONTENTS/MacOS/RemoteAI"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR"
fi

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p "$HOME/Applications"
  rm -rf "$HOME/Applications/RemoteAI.app"
  cp -R "$APP_DIR" "$HOME/Applications/RemoteAI.app"
  echo "$HOME/Applications/RemoteAI.app"
else
  echo "$APP_DIR"
fi
