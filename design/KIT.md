# Kit пиксельного облака

## Канонический визуал

Remote AI использует один утверждённый пиксельный облачный маскот. Источником истины являются шесть PNG в `Sources/RemoteAI/Resources/Mascot/`.

Это runtime-ассеты приложения, а не иллюстрации документации. Процедурный 16×10 Canvas-силуэт больше не является частью продукта.

| State | Asset | Смысл |
| --- | --- | --- |
| `offline` | `mascot-offline.png` | спящее облако + `Z` |
| `connecting` | `mascot-connecting.png` | открытые глаза + янтарные импульсы |
| `syncing` | `mascot-syncing.png` | облако внутри круговых стрелок |
| `thinking` | `mascot-thinking.png` | активное облако + импульсы |
| `waiting` | `mascot-waiting.png` | спокойное облако + пузырь ожидания |
| `error` | `mascot-error.png` | тревожное выражение + красный `!` |

Все исходники 256×256 RGBA на прозрачном фоне. Runtime показывает их через `Image(nsImage:)` с `.interpolation(.none)` и `scaledToFit`, не перерисовывая лицо или контур.

## Характер

Спокойное. Чёткое. Живое. Дружелюбное, но не детское. Маскот должен оставаться читаемым на маленьком плавающем окне и не конкурировать с рабочим контентом.

## Компонент `PixelCloudMascot`

- выбирает PNG только по `MascotState`;
- не накладывает второй набор status-pixels поверх уже нарисованного состояния;
- допускает только микродвижение всего изображения: небольшой float/scale;
- полностью останавливает repeating motion при Reduce Motion;
- использует системный fallback только как аварийную страховку — CI обязан гарантировать наличие всех шести PNG.

## Interaction

- rest — прозрачная floating panel;
- hover — очень небольшой scale-up + system-material halo;
- pressed — небольшой scale-down без bounce;
- основной клик зависит от состояния, context menu остаётся нативным macOS.

## Иконка приложения

`AppIcon.icns` генерируется при сборке из `mascot-thinking.png` на фирменном тёмно-индиговом rounded-square фоне. Таким образом иконка и runtime-маскот используют одно и то же каноническое изображение.

## Проверка

`MascotDesignTests` проверяет, что все шесть состояний имеют читаемый bundled PNG. `ReleaseSnapshotTests` создаёт light/dark screenshots непосредственно из тех же runtime-ассетов. `tools/verify-release.sh` дополнительно проверяет, что все шесть PNG попали внутрь готового `.app`.
