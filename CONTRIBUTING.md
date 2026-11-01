# Как вносить изменения в Remote AI

## Базовый процесс

1. Создайте feature branch от актуального `main`.
2. Для macOS product work прочитайте `AGENTS.md` и соответствующий BAMA skill в `vendor/bama`.
3. Ограничьте задачу одним понятным набором acceptance criteria.
4. Добавьте/обновите tests и snapshots там, где это применимо.
5. Откройте PR на русском языке.
6. Дождитесь полного macOS CI и устраните все failures до merge.

## Проверки локально

```bash
swift test --parallel
swift build -c release
./tools/snap.sh
```

На macOS для полного bundle:

```bash
APP_VERSION=0.2.1 ./build.sh
./tools/verify-release.sh .build/app/RemoteAI.app /tmp/RemoteAI-shots 0.2.1
```

## Язык

README, docs, issue/PR description и весь пользовательский текст Remote AI ведутся на русском. Технические identifiers/API/commands не переводятся. Подробно: `docs/LOCALIZATION.md`.

## Безопасность

PR не принимается, если он:

- отключает SSH host-key checking;
- копирует/читает Claude OAuth/session credentials;
- меняет Mutagen `two-way-safe` на auto-resolve без отдельного security review;
- удаляет remote data до успешного flush;
- вставляет пользовательские значения в shell без validation/quoting;
- скрывает sync conflict;
- вводит пользовательский английский текст без технической необходимости.

## UI

Remote AI — mascot-first приложение, не dashboard. Новый persistent UI требует явного изменения product brief. Нативные macOS controls предпочтительнее кастомных.

## Коммиты и PR

Коммиты должны описывать одно логическое изменение. PR содержит: цель, изменения, проверку, риски/ограничения и screenshots для UI work.
