#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:?использование: verify-release.sh <RemoteAI.app> <папка-снимков> [ожидаемая-версия]}"
SHOTS_DIR="${2:?использование: verify-release.sh <RemoteAI.app> <папка-снимков> [ожидаемая-версия]}"
EXPECTED_VERSION="${3:-}"
PLIST="$APP_DIR/Contents/Info.plist"
EXECUTABLE="$APP_DIR/Contents/MacOS/RemoteAI"
ICON="$APP_DIR/Contents/Resources/AppIcon.icns"

fail() {
  echo "ПРОВЕРКА НЕ ПРОЙДЕНА: $*" >&2
  exit 1
}

[[ -d "$APP_DIR" ]] || fail "bundle приложения не найден: $APP_DIR"
[[ -f "$PLIST" ]] || fail "не найден Info.plist"
[[ -x "$EXECUTABLE" ]] || fail "исполняемый файл RemoteAI отсутствует или не является executable"
[[ -s "$ICON" ]] || fail "AppIcon.icns отсутствует или пуст"

BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw "$PLIST")"
[[ "$BUNDLE_ID" == "app.remoteai.mascot" ]] || fail "неожиданный bundle id: $BUNDLE_ID"

MINIMUM="$(plutil -extract LSMinimumSystemVersion raw "$PLIST")"
[[ "$MINIMUM" == "13.0" || "$MINIMUM" == "14.0" ]] || fail "неожиданная минимальная версия macOS: $MINIMUM"

UI_ELEMENT="$(plutil -extract LSUIElement raw "$PLIST")"
[[ "$UI_ELEMENT" == "true" ]] || fail "LSUIElement должен оставаться true"

DEVELOPMENT_REGION="$(plutil -extract CFBundleDevelopmentRegion raw "$PLIST")"
[[ "$DEVELOPMENT_REGION" == "ru" ]] || fail "CFBundleDevelopmentRegion должен быть ru, получено: $DEVELOPMENT_REGION"

VERSION="$(plutil -extract CFBundleShortVersionString raw "$PLIST")"
if [[ -n "$EXPECTED_VERSION" && "$VERSION" != "$EXPECTED_VERSION" ]]; then
  fail "версия bundle $VERSION не совпадает с ожидаемой $EXPECTED_VERSION"
fi

codesign --verify --deep --strict "$APP_DIR" || fail "codesign verification завершилась ошибкой"

ARCHS="$(/usr/bin/lipo -archs "$EXECUTABLE")"
[[ " $ARCHS " == *" arm64 "* ]] || fail "в релизном бинарнике отсутствует arm64: $ARCHS"
[[ " $ARCHS " == *" x86_64 "* ]] || fail "в релизном бинарнике отсутствует x86_64: $ARCHS"

[[ -d "$SHOTS_DIR" ]] || fail "папка снимков не найдена: $SHOTS_DIR"
COUNT="$(find "$SHOTS_DIR" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
[[ "$COUNT" -ge 16 ]] || fail "ожидалось не менее 16 PNG-снимков, найдено: $COUNT"

required=(
  mascot-offline-light.png mascot-connecting-light.png mascot-syncing-light.png mascot-thinking-light.png mascot-waiting-light.png mascot-error-light.png
  mascot-offline-dark.png mascot-connecting-dark.png mascot-syncing-dark.png mascot-thinking-dark.png mascot-waiting-dark.png mascot-error-dark.png
  mascot-states-light.png mascot-states-dark.png settings-light.png settings-dark.png
)
for name in "${required[@]}"; do
  [[ -s "$SHOTS_DIR/$name" ]] || fail "отсутствует обязательный релизный снимок: $name"
done

for png in "$SHOTS_DIR"/*.png; do
  WIDTH="$(sips -g pixelWidth "$png" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
  HEIGHT="$(sips -g pixelHeight "$png" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
  [[ -n "$WIDTH" && -n "$HEIGHT" && "$WIDTH" -gt 0 && "$HEIGHT" -gt 0 ]] || fail "некорректные размеры PNG: $png"
done

echo "ПРОВЕРКА ПРОЙДЕНА: bundle=$BUNDLE_ID version=$VERSION archs=$ARCHS screenshots=$COUNT"
