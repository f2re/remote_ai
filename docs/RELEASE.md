# CI/CD и выпуск Remote AI

Remote AI собирается и публикуется через GitHub Actions. Релизные сборки — Universal 2 (`arm64 + x86_64`) и проходят обязательную проверку до публикации. Основной пользовательский дистрибутив — `.dmg`; ZIP приложения сохраняется как резервный portable-артефакт.

## CI

Pull request и push в `main` запускают один macOS job:

1. `swift test --parallel`;
2. `swift build -c release`;
3. `./build.sh` — Universal 2 `.app`;
4. `./tools/snap.sh` — 16 детерминированных light/dark PNG;
5. `./tools/verify-release.sh` — metadata, codesign, architectures и screenshots;
6. `tools/create-dmg.sh` — DMG с `RemoteAI.app` и ссылкой на `/Applications`;
7. проверка DMG/ZIP + SHA-256;
8. загрузка единого проверенного CI artifact.

Feature-branch push не дублирует тяжёлую Universal-сборку: при открытом PR работает PR-run. `release/**` обслуживается отдельным Release workflow.

## Dry run

Обычная ветка `release/**`, не совпадающая с `release/publish-v*`, либо ручной запуск workflow **«Релиз»** создаёт проверенный release candidate, но не публикует GitHub Release.

## Публичный release candidate без Apple Developer ID

Для технической приёмки разрешён **только явный предварительный выпуск** с номером `vMAJOR.MINOR.PATCH-rc.N`. Он получает пометку **Pre-release** и предупреждение об отсутствии Apple Developer ID/notarization. Наличие хотя бы одного неполного Apple secret всё равно блокирует сборку. Стабильные теги `vMAJOR.MINOR.PATCH` продолжают требовать полную Apple подпись и notarization.

После успешного macOS CI создайте ветку из текущего `main`:

```bash
git switch main
git pull --ff-only
git switch -c release/prerelease-v0.2.3-rc.1
git push -u origin release/prerelease-v0.2.3-rc.1
```

Этот push собирает DMG/ZIP, проверяет приложение, затем создаёт тег `v0.2.3-rc.1` и GitHub Release **Pre-release** с русскими заметками `docs/releases/v0.2.3-rc.1.md`. Следующий job публикует тот же DMG в GitHub Packages / GHCR. Подписанный стабильный `v0.2.3` выпустите позднее только с действительным сертификатом Apple. Бинарник unsigned RC **не** должен называться notarized, trusted или stable.

## Публикация — основной путь

**Только после** успешного тестового notarization и добавления `docs/releases/v0.2.3.md` с соответствующим изменением версии создайте publish-ветку. Без Apple credentials release gate отклонит публикацию до создания нового тега.

Из текущего зелёного `main` создайте и отправьте ветку:

```bash
git switch main
git pull --ff-only
git switch -c release/publish-v0.2.3
git push -u origin release/publish-v0.2.3
```

Дополнительный marker commit не требуется. Сам push новой publish-ветки запускает транзакцию выпуска.

Release workflow:

1. убеждается, что publish-ветка основана на текущем `main`;
2. checkout-ит точный `main` commit, а не отдельный release marker;
3. запускает тесты и финальную Universal 2 сборку;
4. проверяет `.app` и snapshots;
5. при наличии credentials выполняет Developer ID signing и notarization приложения;
6. собирает DMG с drag-to-Applications layout;
7. при наличии credentials подписывает и отдельно notarize/staple-ит DMG;
8. проверяет DMG через `hdiutil verify` и считает SHA-256;
9. создаёт или подтверждает неизменяемый `vMAJOR.MINOR.PATCH` tag на проверенном `main` SHA;
10. берёт русские release notes из `docs/releases/vMAJOR.MINOR.PATCH.md`;
11. публикует GitHub Release и assets.

Файл release notes обязателен. Автоматический `--generate-notes` намеренно не используется, чтобы пользовательский текст выпуска оставался русским и контролируемым.

**Опубликованные артефакты неизменяемы:** release workflow проверяет наличие GitHub Release с тем же тегом до сборки и отклоняет повторную публикацию. Команды `gh release edit`, `upload --clobber` не используются. Если тег создан, но выпуск не завершился, можно повторить publish-ветку при условии, что GitHub Release ещё отсутствует. Если релиз уже существует, исправление выпускается новым номером версии.

Политика `tools/release-policy.sh` валидирует формат версии и ссылки, тип запуска и полный набор Apple secrets; логика покрыта offline-тестами `tools/test-release-policy.sh`. Вывод `notarytool submit --wait --output-format json` обязательно проверяется `tools/verify-notarization.py`: только явный статус `Accepted` вместе с корректным submission ID разрешает `stapler` и последующую публикацию. Тесты выполняются в macOS CI и Release workflow.

## Внешний tag

Поддерживается и ручной `v*` tag, но его target обязан входить в `main`. Для него используется тот же release gate и тот же `docs/releases/<tag>.md`.

## GitHub Packages: OCI-пакет установщика

GitHub Releases и GitHub Packages — независимые разделы GitHub. DMG из Release сам по себе **не публикуется** в Packages. Для этого в репозитории настроен отдельный workflow `.github/workflows/packages.yml`: он скачивает DMG и `SHA256SUMS.txt` из уже опубликованного GitHub Release, проверяет SHA-256, затем с помощью ORAS публикует оба файла как **OCI-артефакт** в GitHub Container Registry (GHCR). После записи workflow скачивает пакет обратно и сравнивает байты DMG.

Адрес пакета: `ghcr.io/f2re/remote_ai:<tag>` (например, `ghcr.io/f2re/remote_ai:v0.2.2`). Используется `GITHUB_TOKEN` с разрешениями `contents: read` и `packages: write`, без личных PAT. В OCI metadata включена ссылка `org.opencontainers.image.source` на этот репозиторий, чтобы пакет привязывался к нему. Первый пакет в GHCR может быть создан **приватным**: если он должен быть общедоступным, измените visibility в настройках пакета GitHub.

Для повторной загрузки существующего релиза v0.2.2 предусмотрена одноразовая ветка `packages/publish-v0.2.2` от `main`. Она не изменяет сам GitHub Release, не пересобирает и не переподписывает DMG. Повторное использование занятого OCI-тега отклоняется, чтобы не перезаписывать поставленные версии.

Важно: **OCI-пакет не является Docker-приложением**. Скачивать и устанавливать DMG на macOS удобнее через GitHub Releases. OCI здесь — дополнительное хранилище проверенных установщиков и отображение версии на вкладке Packages.

## Assets

Успешный выпуск прикладывает:

- `RemoteAI-<version>-macOS.dmg` — основной установочный образ;
- `RemoteAI-<version>-macOS.zip` — резервный архив приложения;
- `RemoteAI-<version>-screenshots.zip`;
- `SHA256SUMS.txt`;
- отдельные light/dark PNG состояний маскота и Настроек.

DMG содержит `RemoteAI.app` и ссылку `Applications`, поэтому штатная установка — открыть образ и перетащить приложение в `Applications`.

## Developer ID и notarization

GitHub Actions secrets:

- `MACOS_CERTIFICATE_P12`;
- `MACOS_CERTIFICATE_PASSWORD`;
- `APPLE_ID`;
- `APPLE_TEAM_ID`;
- `APPLE_APP_PASSWORD`.

При полном наборе credentials workflow импортирует сертификат во временный keychain, подписывает приложение с Hardened Runtime и timestamp, отправляет ZIP приложения в `notarytool`, выполняет staple/validate и Gatekeeper verification. После этого создаётся DMG, подписывается той же Developer ID identity, отдельно отправляется в `notarytool` и получает staple ticket. После выполнения job временный keychain и копия сертификата удаляются.

**Публичные выпуски теперь fail-closed.** Если хотя бы одного из пяти секретов нет, ветка `release/publish-v*` или внешний тег `v*` не публикуются. Если настроена только часть секретов, падает даже dry run с объяснением причины. Ручной `workflow_dispatch` и непубликующие ветки `release/**` могут создавать ad-hoc signed кандидаты только при полном отсутствии секретов; такие кандидаты никогда не становятся GitHub Release.

## Первичная настройка Apple Developer ID (один раз)

Нужны активное участие в Apple Developer Program и доступ к сертификату **Developer ID Application** с соответствующим приватным ключом. Сертификат `Developer ID Installer` для DMG не подходит (он предназначен для `.pkg`).

1. В [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list) создайте или найдите `Developer ID Application`. На Mac, где создан ключ, откройте **Keychain Access → My Certificates** и экспортируйте сертификат **вместе с приватным ключом** как защищённый паролем файл `.p12`. Один файл `.cer` без приватного ключа недостаточен.
2. Найдите десятисимвольный **Team ID** Apple Developer и email Apple ID. На [account.apple.com](https://account.apple.com/) создайте **App-Specific Password** для notarization (не основной пароль Apple ID).
3. На своём Mac установите GitHub CLI при необходимости (`brew install gh`), выполните `gh auth login` с правом управлять Actions secrets репозитория и перейдите в каталог проекта.
4. Загрузите credentials с локального Mac, без передачи их через чат:

```bash
bash tools/configure-apple-signing.sh ~/Downloads/DeveloperID.p12
```

Скрипт интерактивно запрашивает Apple ID, Team ID, пароль файла `.p12` и app-specific password. Последовательность запускает `gh secret set` через stdin, не печатает приватные значения и не записывает их в файлы проекта. После успешной загрузки удалите ненужные временные копии `.p12` со своего Mac и храните оригинал защищённо.

5. Проверьте наличие именно **имён**, не значений, в [Settings → Secrets and variables → Actions](https://github.com/f2re/remote_ai/settings/secrets/actions). Для исключения незапланированной публикации ограничьте право push к веткам `release/publish-v*` и создания тегов `v*` через правила защиты репозитория.
6. Проверьте подпись без публикации: **Actions → Релиз → Run workflow**, выберите `main`, оставьте version `0.2.3` (или передайте актуальную версию); либо:

```bash
gh workflow run release.yml --repo f2re/remote_ai --ref main -f version=0.2.3
```

В Actions должны успешно завершиться **«Импорт сертификата Developer ID»**, **«Notarization приложения и staple»** и **«Notarization DMG и staple»**. У ручного запуска не создаются тег и публичный Release. Сборку можно скачать в Actions artifacts.

7. Только после успешного тестового прогона выпустите **новую версию**: подготовьте `docs/releases/v0.2.3.md`, обновите версию в соответствующих файлах и создайте `release/publish-v0.2.3` от текущего `main`. Тег `v0.2.2` уже опубликован как неподтверждённый prerelease — не подменяйте опубликованный пакет без прозрачного перевыпуска.

**Безопасность:** не присылайте файл `.p12`, пароль от него или app-specific password в чат, pull request, Issue и логи CI. Доступ к secrets получают только авторизованные GitHub Actions job.

## Версионирование

`Resources/Info.plist` содержит development baseline. В CI/CD `APP_VERSION` и `BUILD_NUMBER` переопределяют `CFBundleShortVersionString` и `CFBundleVersion` только внутри собранного `.app`.

`tools/verify-release.sh` отклоняет bundle с неожиданной версией.
