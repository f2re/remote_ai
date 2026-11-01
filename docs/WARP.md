# Интеграция с Warp

Remote AI использует Warp как интерактивную поверхность передачи управления, а не как дополнительный backend.

## Один клик

Когда Claude активен или ожидает пользователя, клик по маскоту открывает generated Warp Tab Config выбранного workspace.

```text
маскот Remote AI
      │ клик
      ▼
~/.warp/tab_configs/remote_ai_<workspace>.toml
      │ warp://tab_config/<workspace>
      ▼
┌────────────────────────────┬─────────────────────────────────┐
│ Локальный обзор            │ Текущий Claude Code             │
│ реальный local checkout    │ SSH → существующий remote tmux │
│                            │                                 │
│ git status                 │ тот же Claude Code process      │
│ изменённые tracked files   │ существующий transcript         │
│ untracked files            │ prompts / approvals / steering │
│ diff --stat                │                                 │
└────────────────────────────┴─────────────────────────────────┘
```

Правая панель присоединяется к существующей tmux-сессии и не запускает второй Claude. Закрытие Warp только отсоединяет terminal client.

Левая панель использует настоящий локальный Git checkout после синхронизации Mutagen. `.git` не синхронизируется на сервер.

## Почему Tab Config

Обычный `warp://` URI не является безопасным каналом произвольной startup-команды. Generated Tab Config задаёт layout и команды, а URI только открывает named config.

## Локальный обзор

Remote AI формирует русские заголовки: проект, сервер, состояние Git, изменённые отслеживаемые файлы, неотслеживаемые файлы и сводка изменений. Сами Git commands/paths не переводятся. После выводов панель остаётся обычным shell для тестов и ручной проверки.

Правая панель сфокусирована изначально: пользователь продолжает существующий разговор Claude Code, подтверждает действия или задаёт следующую команду.

## Warp Remote Control

Warp может публиковать third-party Claude Code session через Remote Control. Remote AI не включает эту функцию автоматически, поскольку она меняет privacy boundary и может отправлять live terminal session в облако Warp. Возможная будущая интеграция должна быть только явным действием пользователя с ясным предупреждением.

## Безопасность

- Не записывать Claude OAuth/session tokens в Warp config.
- Не сохранять transcript только ради review pane.
- Не отключать SSH host-key checking.
- Shell-quote SSH commands и TOML-escape generated strings.
- Держать Git metadata локально.
