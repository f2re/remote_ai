# План полнофункционального Remote AI

## Выполненный этап: v0.2.0

Пакеты были делегированы локальным агентам и объединены через один релизный PR:

1. `remote-runtime` — deterministic preflight, ограниченные SSH attempts, dependency checks, восстановление существующей tmux/Claude-сессии и понятные ошибки.
2. `sync-engineer` — route-scoped Mutagen session identity без скрытого переиспользования старого endpoint; сохранены `two-way-safe` и видимые конфликты.
3. `macos-ui` — компактная Диагностика в нативных Настройках, `Проверить настройку` и `Запустить / переподключить` без dashboard.
4. `qa-security` — unit coverage, Universal 2, release verification, snapshots, CI artifacts и tag guards.

v0.2.0 успешно собран, прошёл macOS CI и опубликован.

## Текущий этап: v0.2.1 — русскоязычный продукт

Цель: русский язык должен быть частью продуктового контракта, а не переводом отдельных кнопок.

Acceptance:

- Settings, context menu, accessibility, notifications, validation/runtime/SSH/Mutagen diagnostics — на русском;
- основной runtime status не показывает сырой англоязычный pane output;
- Warp review headings — русские;
- fallback parser понимает релевантные русские и английские markers;
- README, CHANGELOG, design/docs, local agent prompts, GitHub templates и CI/CD presentation — русские;
- `CFBundleDevelopmentRegion=ru`;
- release screenshots содержат русские подписи и не обрезаны;
- release notes берутся из подготовленного русскоязычного `docs/releases/vX.Y.Z.md`, без `--generate-notes`;
- `swift test --parallel`, release compile, Universal 2 packaging, codesign, snapshots и archive verification проходят в macOS CI.

## Остающиеся environment-dependent проверки

Автоматический CI не может подтвердить поведение на пользовательском SSH-хосте с реальной авторизацией Claude. Отдельная E2E-приёмка включает reconnect, prompt → work → waiting, notification, two-way propagation, конфликт, flush/Stop и Warp/Terminal handoff.
