# CI/CD и выпуск Remote AI

Remote AI собирается и публикуется через GitHub Actions. Релизные сборки — Universal 2 (`arm64 + x86_64`) и проходят обязательную проверку до публикации.

## CI

Pull request и push в `main` запускают один macOS job:

1. `swift test --parallel`;
2. `swift build -c release`;
3. `./build.sh` — Universal 2 `.app`;
4. `./tools/snap.sh` — 16 детерминированных light/dark PNG;
5. `./tools/verify-release.sh` — metadata, codesign, architectures и screenshots;
6. проверка ZIP + SHA-256;
7. загрузка единого проверенного CI artifact.

Feature-branch push не дублирует тяжёлую Universal-сборку: при открытом PR работает PR-run. `release/**` обслуживается отдельным Release workflow.

## Dry run

Обычная ветка `release/**`, не совпадающая с `release/publish-v*`, либо ручной запуск workflow **«Релиз»** создаёт проверенный release candidate, но не публикует GitHub Release.

## Публикация — основной путь

Из текущего зелёного `main` создайте и отправьте ветку:

```bash
git switch main
git pull --ff-only
git switch -c release/publish-v0.2.1
git push -u origin release/publish-v0.2.1
```

Дополнительный marker commit не требуется. Сам push новой publish-ветки запускает транзакцию выпуска.

Release workflow:

1. убеждается, что publish-ветка основана на текущем `main`;
2. checkout-ит точный `main` commit, а не отдельный release marker;
3. запускает тесты и финальную сборку;
4. проверяет Universal 2 app и snapshots;
5. при наличии credentials выполняет Developer ID signing/notarization;
6. создаёт или подтверждает неизменяемый `vMAJOR.MINOR.PATCH` tag на проверенном `main` SHA;
7. берёт русские release notes из `docs/releases/vMAJOR.MINOR.PATCH.md`;
8. публикует GitHub Release и assets.

Файл release notes обязателен. Автоматический `--generate-notes` намеренно не используется, чтобы пользовательский текст выпуска оставался русским и контролируемым.

## Внешний tag

Поддерживается и ручной `v*` tag, но его target обязан входить в `main`. Для него используется тот же release gate и тот же `docs/releases/<tag>.md`.

## Assets

Успешный выпуск прикладывает:

- `RemoteAI-<version>-macOS.zip`;
- `RemoteAI-<version>-screenshots.zip`;
- `SHA256SUMS.txt`;
- отдельные light/dark PNG состояний маскота и Настроек.

## Developer ID и notarization

GitHub Actions secrets:

- `MACOS_CERTIFICATE_P12`;
- `MACOS_CERTIFICATE_PASSWORD`;
- `APPLE_ID`;
- `APPLE_TEAM_ID`;
- `APPLE_APP_PASSWORD`.

При полном наборе credentials workflow импортирует сертификат во временный keychain, подписывает hardened runtime, отправляет ZIP в `notarytool`, выполняет staple/validate, `spctl --assess` и повторную проверку bundle.

Если credentials отсутствуют, приложение ad-hoc signed, а GitHub Release автоматически помечается как **prerelease**. Такой build остаётся Universal 2 и codesign-verified, но Gatekeeper может потребовать дополнительные действия пользователя.

Secrets не сохраняются в репозитории.

## Версионирование

`Resources/Info.plist` содержит development baseline. В CI/CD `APP_VERSION` и `BUILD_NUMBER` переопределяют `CFBundleShortVersionString` и `CFBundleVersion` только внутри собранного `.app`.

`tools/verify-release.sh` отклоняет bundle с неожиданной версией.
