# Remote AI Astra — Qt5 desktop MVP

**Статус: экспериментальный Linux-порт. Не объявлен совместимым с Astra Linux 1.7/1.8 до испытаний на самих Astra.**

В код добавлены шесть состояний из macOS PNG, прозрачное draggable окно Qt5, системное меню, настройки XDG через QSettings, неблокирующий SSH/tmux-controller и начальная реализация синхронизации Mutagen в режиме two-way-safe с flush перед запуском. Приложение не работает от root и не сохраняет credentials Claude.

## Сборка

Нужны CMake, C++17, qtbase5-dev, dpkg-dev, openssh-client, а для фактического runtime отдельно установленный Mutagen и tmux/Claude Code на сервере.

    cmake -S linux -B /tmp/remote-ai-astra-build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build /tmp/remote-ai-astra-build --parallel 2
    ctest --test-dir /tmp/remote-ai-astra-build --output-on-failure
    (cd /tmp/remote-ai-astra-build && cpack -G DEB)

Проверка без дисплея: QT_QPA_PLATFORM=offscreen /tmp/remote-ai-astra-build/remote-ai-astra --smoke

## DEB в CI

.github/workflows/astra-ci.yml собирает два **compatibility preview DEB** в Debian 10 (ориентир для Astra 1.7) и Debian 12 (ориентир для Astra 1.8). Проверяет unit-тесты, offscreen smoke, dpkg-deb и SHA256. Это **не** нативные сборки Astra и не подтверждение прохождения защитных механизмов Fly. Нужны self-hosted Astra runner/VM и отдельная визуальная/установочная приёмка.

## Использование

Через контекстное меню: «Настройки», SSH-хост, логин, порт, опциональный ключ, существующая локальная папка и абсолютный удалённый путь. Сначала добавьте сервер в OpenSSH known_hosts вручную. Перед запуском сервер проверяется на tmux/claude; затем создаётся/восстанавливается двусторонняя синхронизация Mutagen; после flush стартует или восстанавливается tmux. Клик открывает подключение к этой сессии в системном терминале. Stop завершает только удалённый tmux без удаления проекта.

## Ограничения MVP

- Проверка окна пока offscreen; Fly/X11, tray, и масштабирование должны пройти ручную приёмку в двух Astra.
- Пока один локальный проект/сервер. Несколько рабочих областей, lifecycle hooks Claude Code, расширенный Git review и полная диагностика остаются задачами #37–#40.
- Thinking/waiting из tmux определяется совместимым fallback; при отсутствии признаков работы показывается waiting, а не неподтверждённый thinking.
- SSH требует StrictHostKeyChecking=yes и BatchMode=yes; доверие host key настраивает пользователь.
- Локальный Mutagen устанавливается отдельно, без скрытой загрузки стороннего исполняемого кода.
- Отсутствуют сертификационные утверждения о мандатном контроле доступа Astra Linux.
