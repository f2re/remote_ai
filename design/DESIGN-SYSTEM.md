# Дизайн-система Remote AI

## Характер

Спокойный, тихий, уверенный. Приложение должно ощущаться нативным для macOS, а одна отличительная идентичность — чёткое пиксельное облако.

## Граница системы

Нативные macOS surfaces используются для Настроек, меню, notifications, alerts, keyboard behavior и accessibility. Custom drawing зарезервирован за маскотом и маленькими status pixels.

## Палитра

- тело облака — адаптивные tones для light/dark;
- outline — более сильный neutral;
- status accents — semantic system colors вместе с expression/shape/motion;
- не использовать декоративные gradients;
- смысл состояния не зависит только от цвета.

## Метрики

- hit area маскота: 76–84 pt;
- pixel-art body: около 60–64 pt;
- pixel unit масштабируется целым числом и выравнивается по whole points;
- hover меняет scale, но не layout bounds;
- floating panel по умолчанию без видимой card background.

## Движение

Вся анимация использует shared motion tokens.

- hover — быстрый low-amplitude scale;
- state transition — короткое easing;
- active idle — очень медленный vertical drift 1–2 pt;
- syncing — маленькие orbiting pixels;
- thinking — gentle drift + sparse sparkle;
- waiting — статичное или почти статичное;
- error — без shake loop, только concerned expression + warning cluster.

Reduce Motion выключает repeating drift/orbit/sparkle. Состояния остаются различимы статически.

## Поверхности

- Маскот: transparent, borderless, nonactivating `NSPanel`, draggable, across Spaces/full-screen auxiliary.
- Context menu: нативное SwiftUI/macOS menu.
- Настройки: нативный Settings scene + Form.
- Warp/Terminal: внешние инструменты, не embedded dashboard.

## Типографика и язык

На постоянной поверхности маскота нет текста. Tooltips, Настройки и notifications используют system typography. Все пользовательские строки Remote AI — русские по `docs/LOCALIZATION.md`.

## Взаимодействие

- первый клик ведёт к недостающему setup step;
- `offline/error` → Запустить / переподключить;
- active → Открыть обзор в Warp;
- right click → native context menu;
- hover → subtle scale/halo без сдвига;
- VoiceOver сообщает semantic state.

## Accessibility

- meaning never color-only;
- маскот — настоящий `Button`;
- уважать Reduce Motion/Reduce Transparency;
- слова actions/tooltips соответствуют `docs/GLOSSARY.md`.

## Правило для агентов

Feature views не вводят raw mascot colors, radii, scale factors или animation durations. Сначала добавить token в `Sources/RemoteAI/UI/MascotDesign.swift`. Новые пользовательские строки должны быть русскими.
