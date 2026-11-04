# Astra Linux 1.7–1.8: план работ и качество

## Архитектура

macOS SwiftUI/AppKit остаётся в Sources/RemoteAI. Linux Qt5/C++17 реализуется в linux/. Изображения маскота используются совместно из Sources/RemoteAI/Resources/Mascot, единый порядок состояний: offline > connecting > syncing > thinking > waiting > error. Приоритет конфликта синхронизации над работой Claude обязательный.

## Агентские workstreams

- #37 astra-ui: Qt5/Fly, tray/window, настройки, DPI/accessibility и реальные снимки в Fly.
- #38 astra-runtime: SSH/tmux, Claude lifecycle hooks, Mutagen names, reconnect and conflict semantics.
- #39 debian-packaging: DEB metadata/install/upgrade/remove для обеих Astra.
- #40 astra-ci-qa: независимая приёмка, нативные Astra runner/VM, публикация Release+GHCR.

Параллельный запуск в Claude Code после установки локального claude CLI:

    ./scripts/claude-bama.sh --worktree astra-ui --agent astra-ui "Реализуй issue #37 и создай PR, не изменяй main."
    ./scripts/claude-bama.sh --worktree astra-runtime --agent astra-runtime "Реализуй issue #38 и создай PR, не изменяй main."
    ./scripts/claude-bama.sh --worktree astra-deb --agent debian-packaging "Реализуй issue #39 и создай PR, не изменяй main."
    ./scripts/claude-bama.sh --worktree astra-ci --agent astra-ci-qa "Реализуй issue #40 и создай PR, не изменяй main."

Команды указаны как сценарии делегирования; наличие issues/agent files само по себе не запускает агентов.

## Критерии готовности

1. Оба DEB успешно собраны в двух целевых **нативных** Astra (не просто Debian proxy).
2. В чистой Astra 1.7/1.8 пакет устанавливается, приложение запускается и видимо в меню Fly и tray.
3. Клик/перемещение/контекстное меню, русские строки, шесть состояний и high-DPI работают.
4. SSH-клиент не отключает host-key check; изменённые пользовательские значения не исполняются как shell.
5. Mutagen two-way-safe не перезаписывает конфликты и выполняет flush перед остановкой/удалением файлов.
6. Подтверждены reconnect, существующая tmux-сессия, статус Claude Code и уведомления без чтения credentials.
7. DEB install/upgrade/remove и GitHub Release/GHCR с sha256, provenance, SBOM проходят.
8. Компоненты для работы в защищённом окружении проверяются на целевой политике Astra отдельно.

Официальная документация: https://docs.astralinux.ru/latest/desktop/cpp/qt5/ и https://docs.astralinux.ru/latest/mobile/apackage/.

## Текущий статус

В текущем MVP реализованы Qt5 GUI, базовый remote runtime, Mutagen sync и DEB compatibility matrix. Debian10/12-сборки — только инженерная ранняя проверка ABI. Отдельные собственные Astra runners нужны для подтверждённого пакета 1.7/1.8 и выпуска без предупреждений.
