# Делегированный backlog

`orchestrator` отвечает за интеграцию, а рабочие пакеты распределяются между специализированными агентами.

## macos-ui

Владение: accessory lifecycle, floating `NSPanel`, маскот, context menu, Настройки, notifications и accessibility.

Acceptance: нет обычного document window; VoiceOver получает смысловое русское состояние; пользователь выбирает папку и запускает/останавливает сессию через `AppModel`; light/dark/Reduce Motion snapshots корректны.

## remote-runtime

Владение: SSH reachability, remote workspace bootstrap, tmux start/reuse/kill, bounded pane capture и attach commands.

Acceptance: все user-derived remote values quoted/sanitized; missing tmux/claude даёт понятную русскую ошибку; один poll — один SSH round trip; credentials Claude не читаются.

## sync-engineer

Владение: Mutagen detection, create/resume/flush/pause, endpoint generation, ignore list, conflict/status parsing и route identity.

Acceptance: `two-way-safe`; конфликт → ошибка; custom port соответствует Mutagen SSH endpoint; `.git` игнорируется; смена route не переиспользует старую session.

## qa-security

Владение: tests, failure injection, shell/credential review, localization gate, Universal 2/package/release verification.

Acceptance: `swift test` не требует SSH/Mutagen; snapshots детерминированы; пользовательские тексты русские; release candidate проходит codesign/lipo/metadata/archive checks.

## orchestrator

Интегрирует пакеты, контролирует state precedence, BAMA workflow, PR/CI и release. Acceptance: README позволяет новому пользователю понять установку без чтения исходников; merge выполняется только после зелёного CI.
