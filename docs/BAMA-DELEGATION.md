# Карта делегирования BAMA

Репозиторий закрепляет `daveebbelaar/bama` в `vendor/bama` и использует его skills как основной процесс разработки macOS.

## Роли и маршрутизация

| Рабочий пакет | BAMA skill | Локальный агент | Основной результат |
| --- | --- | --- | --- |
| UX и язык состояний | `skills/design/ux-design` | `macos-ui` | `docs/BRIEF.md`, `docs/GLOSSARY.md` |
| Нативная визуальная система | `skills/design/mac-design`, `skills/design/design-system` | `macos-ui` | `design/DESIGN-SYSTEM.md`, UI tokens |
| Пиксельное облако | `skills/design/design-kit` | `macos-ui` | `design/KIT.md`, SwiftUI-компоненты |
| SSH/tmux/Claude lifecycle | BAMA code/architecture guidance | `remote-runtime` | remote runtime services |
| Mutagen и sync safety | BAMA architecture/testing guidance | `sync-engineer` | synchronization services |
| Проверка и улучшение | `skills/ship/build-and-verify`, `skills/ship/improve-loop`, `skills/ship/test-mac-app` | `qa-security` | tests, CI, snapshots, release gate |
| Интеграция | router + relevant skills | `orchestrator` | sequencing, acceptance, merge/release |

## Контракт выполнения

1. Перед правкой прочитать owning `SKILL.md`.
2. Ограничить пакет заявленными файлами и acceptance criteria.
3. Сначала фиксировать design/spec, затем implementation, затем verification repairs.
4. Не дублировать BAMA в локальных prompts, кроме проектных invariants Remote AI.
5. Каждый handoff содержит изменённые файлы, выполненные проверки и известные риски.
6. Любой пользовательский текст проверяется по `docs/LOCALIZATION.md`.
7. Merge разрешён только после обязательных build/test/snapshot gates.

Локальные агенты — маршрутизаторы к BAMA, а не альтернативный фреймворк.

## Параллельное выполнение релизного спринта

Зафиксированные автономные рабочие пакеты:

- [#30 — qa-security: release gate, подписание и тесты отказов](https://github.com/f2re/remote_ai/issues/30);
- [#31 — macos-ui: drag-to-Applications DMG, layout и UX-тестирование](https://github.com/f2re/remote_ai/issues/31).

У них **не пересекаются файлы-владения**. В конфигурации обоих агентов установлено `isolation: worktree`: изменения должны выполняться в отдельных рабочих деревьях, не в `main`. Команды запускаются на Mac с установленным и авторизованным Claude Code и с локальным клоном репозитория. После `git pull --ff-only` откройте **два отдельных окна Terminal**:

Окно 1:

```bash
./scripts/claude-bama.sh --worktree release-security --agent qa-security "Реализуй issue https://github.com/f2re/remote_ai/issues/30. Соблюдай AGENTS.md и BAMA; сначала тесты, затем исправления. Создай отдельный PR, не публикуй релиз."
```

Окно 2:

```bash
./scripts/claude-bama.sh --worktree dmg-installer --agent macos-ui "Реализуй issue https://github.com/f2re/remote_ai/issues/31. Соблюдай AGENTS.md и BAMA; UX и проверки на macOS. Создай отдельный PR, не публикуй релиз."
```

Для исполнения нужны локальные Claude Code credentials, права GitHub и доступный `vendor/bama`; скрипт самостоятельно инициализирует submodule. **Создание задач не является автоматическим запуском агентов.** Подтверждайте предложенные ими действия в соответствии с настройками разрешений. Оркестратор проверяет diff, тесты и CI каждого PR и только потом объединяет изменения. Никакие Apple signing secrets агентам для этих задач не передаются.
