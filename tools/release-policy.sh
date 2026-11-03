#!/usr/bin/env bash
# Единый fail-closed gate релиза. stdout: только 0 (ad-hoc) или 1 (Apple signing).
set -euo pipefail

reject() {
  printf 'Ошибка политики релиза: %s\n' "$*" >&2
  exit 1
}

ref_type="${GITHUB_REF_TYPE:-}"
ref_name="${GITHUB_REF_NAME:-}"
version="${APP_VERSION:-}"

[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]] ||
  reject "Недопустимая версия сборки."
[[ "$ref_type" == "branch" || "$ref_type" == "tag" ]] ||
  reject "Неизвестный тип GitHub ref."

publish=0
if [[ "$ref_type" == "tag" ]]; then
  [[ "$ref_name" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    reject "Публичный тег должен иметь формат vMAJOR.MINOR.PATCH."
  [[ "$version" == "${ref_name#v}" ]] ||
    reject "Версия сборки не совпадает с публичным тегом."
  publish=1
elif [[ "$ref_name" == release/publish-v* ]]; then
  [[ "$ref_name" =~ ^release/publish-v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    reject "Публикующая ветка должна иметь формат release/publish-vMAJOR.MINOR.PATCH."
  [[ "$version" == "${ref_name#release/publish-v}" ]] ||
    reject "Версия сборки не совпадает с публикующей веткой."
  publish=1
fi

configured=0
for secret in CERT_PRESENT CERT_PASSWORD_PRESENT APPLE_ID_PRESENT APPLE_TEAM_ID_PRESENT APPLE_APP_PASSWORD_PRESENT; do
  value="${!secret:-false}"
  [[ "$value" == "true" || "$value" == "false" ]] ||
    reject "Некорректная конфигурация флага $secret."
  if [[ "$value" == "true" ]]; then
    configured=$((configured + 1))
  fi
done

if [[ "$configured" -gt 0 && "$configured" -lt 5 ]]; then
  reject "Необходимо настроить все пять Apple secrets либо ни одного."
fi
if [[ "$publish" -eq 1 && "$configured" -ne 5 ]]; then
  reject "Публичный выпуск запрещён без Developer ID и notarization."
fi

if [[ "$configured" -eq 5 ]]; then
  printf '1\n'
else
  printf '0\n'
fi
