# Установочный DMG Remote AI

## Контракт интерфейса

Основной сценарий: открыть `RemoteAI-<version>-macOS.dmg` и перетащить `RemoteAI.app` на ярлык `Applications`. Имя приложения, ресурсы и подпись не должны меняться во время подготовки дискового образа.

Окно Finder — минималистичное, без декоративных подложек или выдуманной графики. Белый фон, крупные значки, App слева, Applications справа. Размер окна примерно 640 × 360 pt, размер значка 128 pt, подписи 14 pt, без toolbar и status bar. Координаты в `tools/dmg-finder-layout.applescript`: приложение (168, 185), папка (470, 185).

## Сборка

**CI и Release:** workflow устанавливает закреплённый `dmgbuild==1.6.7` в изолированное Python virtualenv. Генератор `tools/dmg-settings.py` записывает окно, позиции и иконки непосредственно в `.DS_Store`, без Finder и Apple Events. Образ сразу создаётся как UDZO. Финальный образ обязательно повторно монтируется **только для чтения**, проверяются приложение, подпись, symlink `Applications` и непустой `.DS_Store`. Отсутствие layout-файла теперь приводит к ошибке CI, а не к незаметному выпуску неоформленного DMG.

**Локальный fallback без dmgbuild:** `tools/create-dmg.sh` использует UDRW→UDZO и пытается настроить окно Finder через AppleScript. Если Apple Events запрещены, остаётся базовый корректный drag-to-Applications DMG с предупреждением. Для идентичного CI результату локально установите `dmgbuild==1.6.7` и укажите путь к утилите в `DMGBUILD_BIN`. Без системного Finder этот способ всё равно формирует layout.

Реальное отображение Finder, в особенности масштаб значков и видимость надписей, требует ручной проверки на macOS: CI гарантирует структуру .DS_Store, но не скриншотное качество.

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
