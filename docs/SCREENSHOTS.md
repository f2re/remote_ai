# Актуальные скриншоты Remote AI

Эта страница фиксирует визуальный baseline текущего интерфейса Remote AI.

## Проверенная версия

- ветка-источник: `main`;
- commit: `77d46a67b6f38cc6bdd12ff23ddd7afae0d77c60`;
- версия приложения: `0.2.1`;
- build: `88`;
- GitHub Actions run: `41335605018`;
- Swift: `6.3.3`;
- CI: `swift test`, release compile, Universal 2, bundle/codesign validation и screenshot gate — успешно;
- интерфейс: русский;
- целевая сборка: Universal 2 (`arm64 + x86_64`).

PNG для документации оптимизированы по размеру для GitHub. Содержимое интерфейса взято из детерминированных CI snapshots; в компоновках не добавляются несуществующие окна, меню, кнопки или состояния.

## Обзор интерфейса

![Актуальный интерфейс Remote AI](screenshots/current/overview.png)

`overview.png` — документационная компоновка из текущего `Resources/AppIcon.svg`, фактического light-mode листа состояний маскота и фактического dark-mode окна настроек из одного CI build. Компоновка меняет только размещение кадров и подписи документации; UI внутри кадров не перерисован.

## Состояния маскота

Фактический набор текущей версии включает шесть состояний: «Отключён», «Подключается», «Синхронизирует», «Думает», «Ждёт ввода», «Ошибка».

<p align="center">
  <img src="https://github.com/f2re/remote_ai/releases/download/v0.2.1/mascot-states-light.png" width="760" alt="Состояния маскота Remote AI — светлая тема">
</p>

## Настройки

Текущее окно настроек содержит три группы: «Подключение», «Рабочая папка» и «Поведение». В нём настраиваются SSH-маршрут, удалённая корневая папка, локальный проект, диагностика подключения, уведомления и частота обновления статуса.

<p align="center">
  <img src="https://github.com/f2re/remote_ai/releases/download/v0.2.1/settings-light.png" width="620" alt="Настройки Remote AI — светлая тема">
</p>

## Как обновлять baseline

После изменения UI снимки должны быть пересозданы командой:

```bash
./tools/snap.sh
```

Перед релизом полный набор проверяется через:

```bash
./tools/verify-release.sh .build/app/RemoteAI.app /tmp/RemoteAI-shots 0.2.1
```

Источник snapshot harness: [`Tests/RemoteAITests/ReleaseSnapshotTests.swift`](../Tests/RemoteAITests/ReleaseSnapshotTests.swift). Любое изменение README/документации, показывающее интерфейс, должно использовать текущие CI snapshots или компоновки, построенные только из них. Синтетические рекламные mockup-экраны не считаются доказательством состояния продукта.
