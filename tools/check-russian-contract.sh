#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "ПРОВЕРКА РУССКОЯЗЫЧНОГО КОНТРАКТА НЕ ПРОЙДЕНА: $*" >&2
  exit 1
}

REGION="$(plutil -extract CFBundleDevelopmentRegion raw Resources/Info.plist)"
[[ "$REGION" == "ru" ]] || fail "CFBundleDevelopmentRegion должен быть ru, получено: $REGION"

grep -q 'Remote AI: не в сети' Sources/RemoteAI/Models.swift || fail "не найден канонический русский статус «Не в сети»"
grep -q 'Claude Code ожидает ввода' Sources/RemoteAI/Models.swift || fail "не найден канонический русский статус ожидания"
grep -q 'Проверить настройку' Sources/RemoteAI/SettingsView.swift || fail "не найдена русская кнопка диагностики"
grep -q 'Запустить / переподключить' Sources/RemoteAI/MascotView.swift || fail "не найдено русское основное действие"
grep -q 'Состояние Git' Sources/RemoteAI/WarpIntegration.swift || fail "обзор Warp не содержит русского заголовка"

if grep -q -- '--generate-notes' .github/workflows/release.yml; then
  fail "release workflow не должен генерировать англоязычные notes через --generate-notes"
fi

targets=(
  Sources/RemoteAI
  Resources/Info.plist
  README.md
  CONTRIBUTING.md
  SECURITY.md
  .github/PULL_REQUEST_TEMPLATE.md
  .github/ISSUE_TEMPLATE
)

forbidden=(
  'Choose Project'
  'Start / Reconnect'
  'Open Review in Warp'
  'Attach in Terminal'
  'Quit Remote AI'
  'Settings saved'
  'Test Setup'
  'Testing setup'
  'Remote AI offline'
  'Waiting for input'
  'Connection settings are valid'
  'Local project is not selected'
  'Preparing project mirror'
  'Session stopped after a successful sync'
  'Claude is waiting for input'
)

for phrase in "${forbidden[@]}"; do
  if grep -R -n -F -- "$phrase" "${targets[@]}" >/tmp/remote-ai-language-gate.txt 2>/dev/null; then
    cat /tmp/remote-ai-language-gate.txt >&2
    fail "обнаружена запрещённая старая пользовательская фраза: $phrase"
  fi
done

echo "РУССКОЯЗЫЧНЫЙ КОНТРАКТ ПРОВЕРЕН: интерфейс, metadata и release presentation соответствуют правилам."
