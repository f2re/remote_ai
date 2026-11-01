# Архитектура Remote AI

```text
macOS Remote AI
  AppModel / state machine
  ├─ Mascot UI (SwiftUI во floating NSPanel)
  ├─ ConfigStore
  ├─ WarpIntegration ── generated Tab Config ── локальный обзор + live Claude
  ├─ MutagenController ── OpenSSH transport ── remote workspace
  └─ RemoteRuntimeController ── /usr/bin/ssh ── tmux ── неизменённый claude
                                                   └─ session-only status plugin
                                                      └─ lifecycle state file
```

## Приоритет состояния

`sync conflict/error > offline > connecting > syncing > Claude lifecycle hook > pane fallback`

Конфликт синхронизации остаётся ошибкой, даже если Claude продолжает работать. Потеря SSH переводит приложение в «Не в сети». Начальная подготовка — «Подключение». Сканирование/перенос Mutagen — «Синхронизация». После готовности sync lifecycle hooks Claude сообщают работу/ожидание/ошибку. Анализ последних строк tmux используется только как compatibility fallback.

Сырой англоязычный вывод tmux/Mutagen не является основным пользовательским статусом. `AppModel` отображает интерпретированную русскую формулировку; исходная диагностика может использоваться только как техническая деталь.

## Warp handoff

При активном workspace клик по маскоту открывает Warp вместо отдельного dashboard. Remote AI пишет Tab Config в `~/.warp/tab_configs/remote_ai_<workspace>.toml` и открывает его через `warp://tab_config/<name>`.

Созданная вкладка содержит две панели:

1. **Локальный обзор** — реальный checkout пользователя. Выводит `git status`, изменённые tracked/untracked файлы и `git diff --stat`. После синхронизации Mutagen это авторитетная поверхность проверки изменений агента.
2. **Текущий Claude Code** — выполняет тот же SSH attach, который используется ручным подключением, и присоединяется к существующей tmux-сессии. Второй Claude-процесс не создаётся.

URI Warp сам не исполняет произвольные команды; команды находятся в app-owned Tab Config. Terminal.app остаётся fallback, если Warp отсутствует.

Remote AI не сохраняет transcript Claude для построения обзора. Локальная панель получает информацию об изменениях из Git checkout.

## Мост состояния Claude

Remote AI устанавливает небольшой plugin в `~/.remote-ai/runtime/status-plugin` и при поддержке запускает неизменённый Claude Code с `--plugin-dir`.

Plugin записывает только token состояния и Unix timestamp в `~/.remote-ai/state/<workspace>.state`:

- `SessionStart` → `waiting`;
- `UserPromptSubmit` / `PreToolUse` → `thinking`;
- `PermissionRequest` / релевантный `Notification` → `waiting`;
- `Stop` → `waiting`;
- `StopFailure` → `error`;
- `SessionEnd` → `offline`.

stdin hooks отбрасывается. Prompts, tool inputs, responses, transcripts, OAuth tokens и API keys не копируются и не сохраняются.

## Идентичность workspace

Workspace ID детерминирован по стандартизованному локальному пути. Remote directory и tmux session используют тот же sanitized ID, поэтому reconnect не создаёт дубликаты.

Mutagen session name дополнительно включает hash effective route: host, user, port и remote path. Смена сервера не может незаметно переиспользовать старую сессию.

## Безопасность синхронизации

Используется `two-way-safe`. Локальный разработчик и удалённый Claude могут менять одно дерево, поэтому конфликт не разрешается приоритетом одной стороны. По умолчанию игнорируются `.git`, `.build`, `DerivedData`, `node_modules`, `venv`, `.venv`, `target`, `build`, `dist`.

`.git` намеренно остаётся локальным: это предотвращает одновременное изменение Git metadata с двух машин. Warp review выполняет Git-команды на локальном checkout после синхронизации.

## Граница авторизации

Remote AI не реализует логин в Claude. Он запускает неизменённый `claude` CLI на сервере. Если требуется авторизация, пользователь подключается к существующей удалённой сессии и проходит собственный flow Anthropic. Credential files и access tokens приложение не читает.

## Граница remote commands

Для локальных инструментов используется executable + argv. SSH вызывает remote shell только для tmux/runtime-команд; все пользовательские значения валидируются/quoted. Generated Warp TOML экранируется отдельно.

## Возможные следующие слои

- третья Warp-панель для test/log commands проекта;
- очистка app-owned `remote_ai_*.toml`;
- isolated Mutagen daemon + app-private SSH wrapper/config;
- native background-session provider вместо tmux при повышении минимальной версии Claude Code;
- несколько серверов/workspaces;
- launch-at-login;
- полностью подписанный и notarized distribution.
