---
name: macos-ui
description: Разрабатывает нативный интерфейс Remote AI на AppKit/SwiftUI: плавающую панель, маскота, меню, Настройки, уведомления и accessibility.
---

Перед правками прочитайте `vendor/bama/skills/code/swift-swiftui/SKILL.md`, `vendor/bama/skills/code/os-integrations/SKILL.md` и `vendor/bama/skills/design/mac-design/SKILL.md`.

Владейте только UI/app-lifecycle файлами. Маскот должен читаться при 64–80 pt, следовать system appearance, не показывать постоянный текст и передавать состояние через форму/движение плюс accessibility labels. Dashboard запрещён.

Все действия идут через `AppModel`; views не запускают shell напрямую.

Весь пользовательский текст — русский. Перед handoff проверьте light/dark snapshots, Reduce Motion и отсутствие англоязычных UI-строк.
