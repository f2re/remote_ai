# Установочный DMG Remote AI

## Контракт интерфейса

Основной сценарий: открыть `RemoteAI-<version>-macOS.dmg` и перетащить `RemoteAI.app` на ярлык `Applications`. Имя приложения, ресурсы и подпись не должны меняться во время подготовки дискового образа.

Окно Finder — минималистичное, без декоративных подложек или выдуманной графики. Белый фон, крупные значки, App слева, Applications справа. Размер окна примерно 640 × 360 pt, размер значка 128 pt, подписи 14 pt, без toolbar и status bar. Координаты в `tools/dmg-finder-layout.applescript`: приложение (168, 185), папка (470, 185).

## Сборка

`tools/create-dmg.sh` создаёт временный UDRW-образ, монтирует его в режиме записи, проверяет синтаксис AppleScript, пытается сохранить Finder layout в `.DS_Store`, размонтирует образ, конвертирует в сжатый UDZO, затем монтирует окончательный образ **только для чтения** и проверяет приложение, подпись и цель `Applications`.

Finder через Apple Events может быть недоступен на headless macOS CI. В таком случае оформление пропускается, но штатный drag-to-Applications DMG по-прежнему считается валидным. Причина отображается как предупреждение в GitHub Actions. Не путать успешную проверку DMG со скриншотной приёмкой Finder layout.

Для принудительной проверки fallback:

```bash
DMG_SKIP_FINDER_LAYOUT=1 bash tools/create-dmg.sh \
  .build/app/RemoteAI.app /tmp/RemoteAI-no-finder.dmg "Remote AI Test"
```

## Приёмка на реальном Mac

1. Открыть свежий DMG на Mac с Finder (не использовать распакованный ZIP).
2. Проверить белый фон, два значка и достаточную область для перетаскивания.
3. Перетащить приложение на Applications, убедиться в отсутствии конфликтующих установок и запуске.
4. Закрыть окно и снова открыть DMG: расположение значков должно сохраняться.
5. Сделать screenshot окна Finder и приложить к issue [#31](https://github.com/f2re/remote_ai/issues/31) или PR.
6. Для Apple-signed пакета проверить `spctl --assess --type execute --verbose=4 /Applications/RemoteAI.app` и `xcrun stapler validate <file.dmg>`.

Без пунктов 1–5 задача визуальной приёмки остаётся **открытой**, даже если macOS CI успешно собрал образ.
