# Remote AI

Нативный macOS-маскот для управления постоянной удалённой сессией Claude Code при локальном зеркалировании проекта.

## BAMA

BAMA подключён как submodule `vendor/bama` и является источником правил для нативной macOS-разработки.

```bash
git submodule update --init --recursive
```

Любую продуктовую macOS-задачу начинайте с `vendor/bama/skills/start/bama/SKILL.md`. Не создавайте параллельный дизайн-процесс, если BAMA уже содержит подходящий skill.

Для маскота/UI используйте порядок:

1. `vendor/bama/skills/design/ux-design/SKILL.md`
2. `vendor/bama/skills/design/mac-design/SKILL.md`
3. `vendor/bama/skills/design/design-system/SKILL.md`
4. `vendor/bama/skills/design/design-kit/SKILL.md`
5. `vendor/bama/skills/code/swift-swiftui/SKILL.md`
6. `vendor/bama/skills/ship/build-and-verify/SKILL.md`
7. `vendor/bama/skills/ship/improve-loop/SKILL.md`

Карта делегирования: `docs/BAMA-DELEGATION.md`. GitHub Issues используются как ограниченные work packets с owning skill и acceptance criteria.

Правила дизайна: `design/DESIGN-SYSTEM.md`. Спецификация маскота: `design/KIT.md`.

## Контракт продукта

Remote AI остаётся тихим приложением-компаньоном. Единственная постоянная поверхность — маленькое плавающее пиксельное облако. Состояния: не в сети, подключение, синхронизация, Claude работает, ожидание ввода, ошибка. Конфигурация и разрушительные действия находятся в контекстном меню или Настройках.

Архитектура: Swift/macOS → OpenSSH + Mutagen → remote workspace → tmux → неизменённый Claude Code.

## Неприкосновенные правила

- Не читать, не копировать и не сохранять OAuth/session credentials Claude.
- Mutagen по умолчанию работает только в `two-way-safe`; конфликт — блокирующая видимая ошибка.
- Не очищать remote workspace до успешного flush либо явного согласия пользователя на потерю данных.
- Все shell-boundary значения валидировать и экранировать.
- Не отключать проверку SSH host key.
- Не превращать маскота в dashboard.
- Меню, Настройки, alerts и notifications остаются нативными macOS surfaces.
- Весь пользовательский текст и локальная документация Remote AI должны быть на русском языке. Технические identifiers/API/commands не переводятся.

## Локальные агенты

Это маршрутизаторы к BAMA, а не замена BAMA skills:

- `orchestrator`: интеграция и выбор следующего skill;
- `macos-ui`: UX/design/SwiftUI для маскота, Настроек и уведомлений;
- `remote-runtime`: SSH/tmux/Claude lifecycle;
- `sync-engineer`: Mutagen и workspace mapping;
- `qa-security`: тесты, failure injection, security review и packaging.

## Проверки

```bash
swift build
swift test
./build.sh
```

State transitions должны оставаться детерминированными и проверяться без живого сервера. Реальный remote E2E — отдельный manual gate.
