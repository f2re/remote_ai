#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/tools/release-policy.sh"
passed=0

case_policy() {
  local description="$1" expectation="$2" signing="$3" ref_type="$4" ref_name="$5" version="$6" secrets="$7"
  local cert=false certpass=false appleid=false team=false apppass=false
  local result

  case "$secrets" in
    none) ;;
    partial) cert=true ;;
    four) cert=true; certpass=true; appleid=true; team=true ;;
    all) cert=true; certpass=true; appleid=true; team=true; apppass=true ;;
    malformed) cert=unexpected ;;
    *) echo "Неизвестная тестовая комбинация: $secrets" >&2; exit 1 ;;
  esac

  if result="$(env GITHUB_REF_TYPE="$ref_type" GITHUB_REF_NAME="$ref_name" APP_VERSION="$version" \
      CERT_PRESENT="$cert" CERT_PASSWORD_PRESENT="$certpass" APPLE_ID_PRESENT="$appleid" \
      APPLE_TEAM_ID_PRESENT="$team" APPLE_APP_PASSWORD_PRESENT="$apppass" bash "$SCRIPT" 2>&1)"; then
    if [[ "$expectation" != "ok" || "$result" != "$signing" ]]; then
      printf 'FAIL %s: unexpected success (%s)\n' "$description" "$result" >&2
      exit 1
    fi
  else
    if [[ "$expectation" != "fail" || "$result" != *"Ошибка политики релиза:"* ]]; then
      printf 'FAIL %s: unexpected failure (%s)\n' "$description" "$result" >&2
      exit 1
    fi
  fi

  passed=$((passed + 1))
  printf 'OK %02d — %s\n' "$passed" "$description"
}

case_policy "manual dry-run без credentials" ok 0 branch main 0.2.3 none
case_policy "manual dry-run с полной подписью" ok 1 branch main 0.2.3 all
case_policy "RC release/preflight без credentials" ok 0 branch release/preflight-v0.2.3 0.2.3-rc.42 none
case_policy "publish branch + 5 secrets" ok 1 branch release/publish-v0.2.3 0.2.3 all
case_policy "tag + 5 secrets" ok 1 tag v0.2.3 0.2.3 all
case_policy "publish без credentials запрещён" fail - branch release/publish-v0.2.3 0.2.3 none
case_policy "tag без credentials запрещён" fail - tag v0.2.3 0.2.3 none
case_policy "частичные credentials запрещены в dry-run" fail - branch main 0.2.3 partial
case_policy "четыре credentials запрещены в publish" fail - branch release/publish-v0.2.3 0.2.3 four
case_policy "некорректный флаг secrets запрещён" fail - branch main 0.2.3 malformed
case_policy "неверная версия для publish" fail - branch release/publish-v0.2.3 0.2.2 all
case_policy "неверная версия для tag" fail - tag v0.2.3 0.2.2 all
case_policy "неверная семантика tag" fail - tag v0.2.3-rc.1 0.2.3-rc.1 all
case_policy "постороннее имя publish" fail - branch release/publish-v0.2.3-evil 0.2.3-rc.1 all
case_policy "инъекция в input версии запрещена" fail - branch main '0.2.3"; echo unsafe' all
case_policy "пустая версия запрещена" fail - branch main "" all
case_policy "неизвестный тип ref запрещён" fail - other main 0.2.3 all

echo "ПРОВЕРКА ПРОЙДЕНА: $passed сценариев политики релиза."
