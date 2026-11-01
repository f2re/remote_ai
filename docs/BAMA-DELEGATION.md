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
