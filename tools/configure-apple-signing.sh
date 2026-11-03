#!/usr/bin/env bash
set -euo pipefail
umask 077

REPO="f2re/remote_ai"
CERTIFICATE_PATH="${1:-}"

if [[ "$#" -ne 1 || ! -f "$CERTIFICATE_PATH" ]]; then
  echo "Использование: bash tools/configure-apple-signing.sh /путь/к/DeveloperID.p12" >&2
  exit 2
fi

for tool in gh base64 tr; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Не найдена обязательная команда: $tool" >&2
    exit 1
  }
done

gh auth status >/dev/null || {
  echo "Авторизуйтесь в GitHub CLI: gh auth login" >&2
  exit 1
}

echo "Настройка Apple Developer ID secrets для $REPO"
echo "Пароли вводятся скрыто и не сохраняются в файлах проекта."
read -r -p "Apple ID (email): " APPLE_ID
read -r -p "Apple Team ID (10 символов): " APPLE_TEAM_ID

if [[ -z "$APPLE_ID" || ! "$APPLE_TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "Apple ID или Team ID имеют некорректный формат." >&2
  exit 1
fi

read -r -s -p "Пароль экспорта сертификата .p12: " CERTIFICATE_PASSWORD
printf '\n'
read -r -s -p "App-specific password Apple ID: " APPLE_APP_PASSWORD
printf '\n'

if [[ -z "$CERTIFICATE_PASSWORD" || -z "$APPLE_APP_PASSWORD" ]]; then
  echo "Пароли не могут быть пустыми." >&2
  exit 1
fi

# GitHub CLI читает значение secret со stdin. Никаких приватных ключей в git.
base64 < "$CERTIFICATE_PATH" | tr -d '\r\n' |
  gh secret set MACOS_CERTIFICATE_P12 --repo "$REPO"
printf '%s' "$CERTIFICATE_PASSWORD" |
  gh secret set MACOS_CERTIFICATE_PASSWORD --repo "$REPO"
printf '%s' "$APPLE_ID" |
  gh secret set APPLE_ID --repo "$REPO"
printf '%s' "$APPLE_TEAM_ID" |
  gh secret set APPLE_TEAM_ID --repo "$REPO"
printf '%s' "$APPLE_APP_PASSWORD" |
  gh secret set APPLE_APP_PASSWORD --repo "$REPO"

unset CERTIFICATE_PASSWORD APPLE_APP_PASSWORD

echo "Пять секретов переданы в GitHub Actions. Проверка наличия имён:"
gh secret list --repo "$REPO"
echo "Теперь выполните тестовый workflow_dispatch и проверьте подпись и notarization."
