# Канонический маскот Remote AI

Маскот Remote AI — пиксельное облако с шестью визуальными состояниями. Эти изображения одновременно являются runtime-ресурсами приложения, источником release snapshots и основой значка приложения.

## Файлы

Каноническая директория:

```text
Sources/RemoteAI/Resources/Mascot/
├── mascot-offline.png
├── mascot-connecting.png
├── mascot-syncing.png
├── mascot-thinking.png
├── mascot-waiting.png
└── mascot-error.png
```

Каждый файл — PNG 256×256 RGBA с прозрачным фоном. Нельзя подменять эти файлы процедурным SwiftUI-рисунком или отдельным «похожим» набором для README.

## От состояния к изображению

`MascotAsset` в `PixelCloudMascot.swift` содержит исчерпывающее соответствие `MascotState → PNG`. Ассоциированное значение `.error(String)` влияет на текст ошибки, но визуально использует единый `mascot-error.png`.

## Упаковка

SwiftPM копирует каталог `Resources/Mascot` в `RemoteAI_RemoteAI.bundle`. `build.sh` переносит этот bundle внутрь:

```text
RemoteAI.app/Contents/Resources/RemoteAI_RemoteAI.bundle/Mascot/
```

Runtime сначала ищет packaged resource внутри `Bundle.main.resourceURL`, затем использует `Bundle.module` для `swift run` и тестов.

## Иконка

`scripts/generate-app-icon.swift` использует `mascot-thinking.png` и генерирует 1024×1024 master. `build.sh` строит из него `AppIcon.icns`. Иконка поэтому не должна расходиться с текущим runtime-маскотом.

## Snapshot gate

```bash
./tools/snap.sh /tmp/RemoteAI-shots
./tools/verify-release.sh .build/app/RemoteAI.app /tmp/RemoteAI-shots <version>
```

Release gate требует:
- 6 runtime PNG внутри `.app`;
- 12 individual state screenshots: light + dark;
- 2 state sheets: light + dark;
- 2 Settings screenshots;
- валидный `AppIcon.icns`, codesign и Universal 2.

## Правило обновления

При изменении любого PNG нужно одновременно:
1. обновить все затронутые состояния как единую визуальную семью;
2. прогнать unit tests и snapshot suite;
3. визуально проверить `mascot-states-light.png` и `mascot-states-dark.png`;
4. пересобрать release candidate;
5. обновлять README только фактическими runtime/release изображениями.
