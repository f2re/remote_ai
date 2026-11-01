# User stories Remote AI

BAMA-backlog для интерфейса и эксплуатационного цикла Remote AI. Каждая story достаточно мала для отдельного implementation commit и привязана к ответственному агенту/skill.

## M1 — Маскот и базовый цикл

### S-001 — Язык взаимодействия маскота

Пользователь понимает состояние маскота и результат клика без dashboard.

Acceptance:
- один основной flow от «Не в сети» до «Ожидание ввода» и передачи управления в Warp;
- шесть состояний различимы не только цветом;
- button/tooltip/context menu/Настройки/accessibility используют единый словарь;
- нет нового modal/dashboard/permanent status card.

Статус: **готово**.

### S-002 — Дизайн-система и kit

Пользователь видит спокойного нативного macOS-компаньона с одной узнаваемой кастомной идентичностью.

Acceptance:
- `design/DESIGN-SYSTEM.md` фиксирует metrics, palette, motion и accessibility;
- `design/KIT.md` описывает deterministic pixel-cloud geometry и состояния;
- custom drawing ограничен маскотом/status pixels;
- feature views используют shared tokens.

Статус: **готово**.

### S-003 — State-driven пиксельное облако

Состояния не в сети, подключение, синхронизация, работа, ожидание и ошибка узнаются с первого взгляда.

Acceptance: deterministic geometry tests, code-driven silhouette, distinct expressions/indicators, fixed hit area, без regression context/primary actions.

Статус: **готово**.

### S-004 — Motion и accessibility

Reduce Motion/VoiceOver не лишают пользователя смысла состояния.

Acceptance: static fallback, semantic VoiceOver, context actions без hover, light/dark contrast.

Статус: **готово**.

### S-005 — First-run настройка

При первом клике пользователь попадает к реально отсутствующему шагу, а не в позднюю invalid configuration.

Acceptance: missing host → Настройки; host/no workspace → выбор проекта; configured offline/error → запуск; active → Warp; единый action path.

Статус: **готово**.

## M2 — Проверка и эксплуатационная устойчивость

### S-006 — Build/package/regression gate

Acceptance: `swift test`, release build, Universal 2 packaging, codesign, light/dark snapshots и runtime tests проходят в macOS CI.

Статус: **готово**.

### S-007 — Детерминированные snapshots

UI/QA agents могут без живого сервера получить все шесть состояний и Настройки в light/dark.

Acceptance: `./tools/snap.sh`, 16 PNG, deterministic exit, release verifier.

Статус: **готово**.

### S-008 — Полнофункциональный remote lifecycle

Acceptance: bounded SSH, preflight, route-scoped Mutagen, existing-session restore, Diagnostics, безопасный Stop/flush и transactional CI/CD.

Статус: **готово в v0.2.0**.

## M3 — Русскоязычный продукт

### S-009 — Единый русский интерфейс и репозиторий

Как русскоязычный пользователь и разработчик, я не встречаю случайно смешанный интерфейс или англоязычные проектные инструкции.

Acceptance:
- UI, diagnostics, notifications, accessibility и Remote-AI-authored errors — русские;
- raw external output не является primary status;
- Warp review headings — русские;
- README/docs/design/agents/templates/CI presentation — русские;
- release snapshots — русские и без clipping;
- release notes публикуются из `docs/releases/vX.Y.Z.md`;
- protocol tokens/API/commands остаются технически неизменными;
- полный macOS CI зелёный.

Статус: **выполняется в v0.2.1**.

## Дальше

- несколько одновременных workspaces/servers;
- launch at login;
- опциональные project presets для review/test/log panes;
- полноценная Developer ID/notarized distribution;
- richer history только если она не превращает маскота в dashboard.
