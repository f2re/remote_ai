#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-.build/app/RemoteAI.app}"
OUTPUT_DMG="${2:-RemoteAI.dmg}"
VOLUME_NAME="${3:-Remote AI}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Не найдено приложение для упаковки: $APP_PATH" >&2
  exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "hdiutil недоступен: DMG можно собирать только на macOS." >&2
  exit 1
fi

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/remoteai-dmg-stage.XXXXXX")"
MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/remoteai-dmg-mount.XXXXXX")"
MOUNTED=0

cleanup() {
  if [[ "$MOUNTED" == "1" ]]; then
    hdiutil detach "$MOUNT_DIR" -force >/dev/null 2>&1 || true
  fi
  rm -rf "$STAGE_DIR" "$MOUNT_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

APP_NAME="$(basename "$APP_PATH")"
ditto "$APP_PATH" "$STAGE_DIR/$APP_NAME"
ln -s /Applications "$STAGE_DIR/Applications"

rm -f "$OUTPUT_DMG"
hdiutil create \
  -quiet \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$OUTPUT_DMG"

hdiutil verify "$OUTPUT_DMG" >/dev/null

hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_DIR" "$OUTPUT_DMG" >/dev/null
MOUNTED=1

[[ -d "$MOUNT_DIR/$APP_NAME" ]] || {
  echo "DMG не содержит $APP_NAME" >&2
  exit 1
}
[[ -L "$MOUNT_DIR/Applications" ]] || {
  echo "DMG не содержит ссылку Applications" >&2
  exit 1
}
[[ "$(readlink "$MOUNT_DIR/Applications")" == "/Applications" ]] || {
  echo "Ссылка Applications в DMG указывает не на /Applications" >&2
  exit 1
}

if command -v codesign >/dev/null 2>&1; then
  codesign --verify --deep --strict "$MOUNT_DIR/$APP_NAME"
fi

hdiutil detach "$MOUNT_DIR" >/dev/null
MOUNTED=0
rmdir "$MOUNT_DIR"

printf '%s\n' "$OUTPUT_DMG"
