# Kit пиксельного облака

## Характер

Спокойное. Чёткое. Живое.

## Компонент `PixelCloudMascot`

Назначение: единственная постоянная визуальная идентичность и state-control Remote AI.

### Геометрия

- deterministic pixel grid, отрисованный SwiftUI-кодом;
- компактный 16-column silhouette с мягкой слегка асимметричной верхней частью и устойчивым нижним mass;
- eyes/mouth — отдельные state pixels;
- status particles находятся вне лица и не касаются края hit target;
- SF Symbol не заменяет тело облака.

### Выражения

- **Не в сети** — закрытые горизонтальные глаза, muted body;
- **Подключение** — открытые глаза + moving/search pixel;
- **Синхронизация** — открытые глаза + два orbiting satellites;
- **Claude Code работает** — focused eyes + sparkle + subtle float;
- **Ожидание ввода** — relaxed eyes + маленькая улыбка/steady pixel;
- **Ошибка** — concerned eyes/mouth + compact warning cluster.

### Interaction

- rest — full-size cloud, transparent panel;
- hover — небольшой scale-up + лёгкий system-material halo;
- pressed — небольшой scale-down без bounce;
- unavailable actions disabled в context menu, не через disabled primary mascot.

### Motion

Использовать только `MascotDesign.Motion`. Repeating motion останавливается при Reduce Motion.

### Accessibility

Decorative renderer скрыт от accessibility. `MascotView` предоставляет одну кнопку с русским смысловым label из `MascotState.accessibilityLabel`.

## `StatusPixels`

- connecting — один moving square;
- syncing — два squares на orbit;
- thinking — four-pixel sparkle;
- waiting — steady square;
- error — exclamation-like cluster;
- offline — отсутствует.

## Нативные элементы

Context menu, Настройки, system notifications и Warp/Terminal handoff не переоформляются под custom skin.
