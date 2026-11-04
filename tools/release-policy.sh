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

stable_release=0
if [[ "$ref_type" == "tag" ]]; then
  [[ "$ref_name" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]] ||
    reject "Тег должен иметь формат vMAJOR.MINOR.PATCH или vMAJOR.MINOR.PATCH-rc.N."
  [[ "$version" == "${ref_name#v}" ]] ||
    reject "Версия сборки не совпадает с публичным тегом."
  [[ "$version" == *"-rc."* ]] || stable_release=1
elif [[ "$ref_name" == release/publish-v* ]]; then
  [[ "$ref_name" =~ ^release/publish-v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    reject "Стабильная ветка должна иметь формат release/publish-vMAJOR.MINOR.PATCH."
  [[ "$version" == "${ref_name#release/publish-v}" ]] ||
    reject "Версия сборки не совпадает со стабильной веткой."
  stable_release=1
elif [[ "$ref_name" == release/prerelease-v* ]]; then
  [[ "$ref_name" =~ ^release/prerelease-v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$ ]] ||
    reject "Предварительная ветка должна иметь формат release/prerelease-vMAJOR.MINOR.PATCH-rc.N."
  [[ "$version" == "${ref_name#release/prerelease-v}" ]] ||
    reject "Версия сборки не совпадает с предварительной веткой."
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
if [[ "$stable_release" -eq 1 && "$configured" -ne 5 ]]; then
  reject "Стабильный выпуск запрещён без Developer ID и notarization."
fi

if [[ "$configured" -eq 5 ]]; then
  printf '1\n'
else
  printf '0\n'
fi
