# План полнофункционального Remote AI

## Выполненный этап: v0.2.0

Пакеты были делегированы локальным агентам и объединены через один релизный PR:

1. `remote-runtime` — детерминированная предварительная проверка, ограниченные SSH attempts, dependency checks, восстановление существующей tmux/Claude-сессии и понятные ошибки.
2. `sync-engineer` — route-scoped identity сессии Mutagen без скрытого переиспользования старого endpoint; сохранены `two-way-safe` и видимые конфликты.
3. `macos-ui` — компактная Диагностика в нативных Настройках, «Проверить настройку» и «Запустить / переподключить» без dashboard.
4. `qa-security` — unit coverage, Universal 2, release verification, snapshots, CI artifacts и tag guards.

v0.2.0 успешно собран, прошёл macOS CI и опубликован.

## Этап v0.2.1 — русскоязычный продукт

Цель: русский язык является частью продуктового контракта, а не переводом отдельных кнопок.

Критерии приёмки:

- Настройки, контекстное меню, accessibility, уведомления и validation/runtime/SSH/Mutagen diagnostics — на русском;
- основной runtime status не показывает сырой англоязычный pane output;
- заголовки обзора Warp — русские;
- fallback parser понимает релевантные русские и английские markers;
- README, CHANGELOG, design/docs, local agent prompts, GitHub templates и представление CI/CD — русские;
- `CFBundleDevelopmentRegion=ru`;
- релизные screenshots содержат русские подписи и не обрезаны;
- release notes берутся из подготовленного русскоязычного `docs/releases/vX.Y.Z.md`, без `--generate-notes`;
- CI-gate проверяет ключевые признаки русскоязычного контракта и запрещает возврат известных английских UI-фраз;
- `swift test --parallel`, release compile, Universal 2 packaging, codesign, snapshots и archive verification проходят в macOS CI.

Все переносимые критерии v0.2.1 выполнены и готовы к выпуску.

## Остающиеся проверки, зависящие от окружения

Автоматический CI не может подтвердить поведение на пользовательском SSH-хосте с реальной авторизацией Claude. Отдельная E2E-приёмка включает reconnect, prompt → work → waiting, notification, two-way propagation, конфликт, flush/Stop и Warp/Terminal handoff.
