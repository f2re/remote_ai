#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-.build/app/RemoteAI.app}"
OUTPUT_DMG="${2:-RemoteAI.dmg}"
VOLUME_NAME="${3:-Remote AI}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -d "$APP_PATH" ]] || {
  echo "Не найдено приложение для упаковки: $APP_PATH" >&2
  exit 1
}
command -v hdiutil >/dev/null 2>&1 || {
  echo "hdiutil недоступен: DMG можно собирать только на macOS." >&2
  exit 1
}

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/remoteai-dmg-stage.XXXXXX")"
MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/remoteai-dmg-mount.XXXXXX")"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/remoteai-dmg-work.XXXXXX")"
RW_DMG="$WORK_DIR/RemoteAI-rw.dmg"
MOUNTED=0

cleanup() {
  if [[ "$MOUNTED" == "1" ]]; then
    hdiutil detach "$MOUNT_DIR" -force >/dev/null 2>&1 || true
  fi
  rm -rf "$STAGE_DIR" "$MOUNT_DIR" "$WORK_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

APP_NAME="$(basename "$APP_PATH")"
ditto "$APP_PATH" "$STAGE_DIR/$APP_NAME"
ln -s /Applications "$STAGE_DIR/Applications"

# Даже в headless CI AppleScript обязан успешно проходить синтаксическую проверку.
if command -v osacompile >/dev/null 2>&1; then
  osacompile -o "$WORK_DIR/dmg-finder-layout.scpt" "$SCRIPT_DIR/dmg-finder-layout.applescript"
fi

if [[ -n "${DMGBUILD_BIN:-}" ]]; then
  [[ -x "$DMGBUILD_BIN" ]] || {
    echo "Указан недоступный dmgbuild: $DMGBUILD_BIN" >&2
    exit 1
  }
  ABS_APP_PATH="$(cd "$(dirname "$APP_PATH")" && pwd)/$APP_NAME"
  rm -f "$OUTPUT_DMG"
  "$DMGBUILD_BIN" -s "$SCRIPT_DIR/dmg-settings.py" \
    -D "app=$ABS_APP_PATH" \
    "$VOLUME_NAME" "$OUTPUT_DMG"
  echo "Headless Finder layout записан dmgbuild без Apple Events."
else
  # Finder записывает настройки положения и размеров значков в .DS_Store только на
  # смонтированный записываемый том. После настройки DMG конвертируется в сжатый UDZO.
  hdiutil create -quiet \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov -format UDRW \
    "$RW_DMG"

  hdiutil attach -readwrite -nobrowse -mountpoint "$MOUNT_DIR" "$RW_DMG" >/dev/null
  MOUNTED=1

  # Окно Finder — опциональное оформление. В headless CI Apple Events могут быть
  # запрещены. Не разрушать корректный drag-to-Applications пакет из-за Finder.
  if [[ "${DMG_SKIP_FINDER_LAYOUT:-0}" != "1" ]] && command -v osascript >/dev/null 2>&1; then
    if command -v perl >/dev/null 2>&1 && \
      perl -e 'alarm shift; exec @ARGV or die $!' 20 \
        /usr/bin/osascript "$SCRIPT_DIR/dmg-finder-layout.applescript" "$VOLUME_NAME" "$APP_NAME" >/dev/null 2>&1; then
      if [[ -s "$MOUNT_DIR/.DS_Store" ]]; then
        echo "Finder layout записан в образ."
      else
        echo "::warning::Finder не записал .DS_Store. Сохранён базовый DMG." >&2
      fi
    else
      echo "::warning::Finder недоступен: сохранён стандартный drag-to-Applications DMG." >&2
    fi
  fi

  sync
  hdiutil detach "$MOUNT_DIR" >/dev/null
  MOUNTED=0

  rm -f "$OUTPUT_DMG"
  hdiutil convert "$RW_DMG" \
    -quiet -format UDZO \
    -imagekey zlib-level=9 \
    -o "$OUTPUT_DMG"
fi

hdiutil verify "$OUTPUT_DMG" >/dev/null

# После convert повторно монтируем уже финальный read-only образ.
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_DIR" "$OUTPUT_DMG" >/dev/null
MOUNTED=1

if [[ -n "${DMGBUILD_BIN:-}" && ! -s "$MOUNT_DIR/.DS_Store" ]]; then
  echo "Headless DMG должен содержать .DS_Store с оформлением Finder." >&2
  exit 1
fi

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
printf '%s\n' "$OUTPUT_DMG"
