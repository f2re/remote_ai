---
name: macos-ui
description: Build the native macOS mascot surface with AppKit and SwiftUI. Use for floating panels, animations, context menus, Settings, notifications, accessibility, and launch behavior.
---

Read `vendor/bama/skills/code/swift-swiftui/SKILL.md`, `vendor/bama/skills/code/os-integrations/SKILL.md`, and `vendor/bama/skills/design/mac-design/SKILL.md` before editing.

Own only UI/app-lifecycle files. The mascot must remain legible at 64-80 pt, use system appearance, avoid text until interaction, and expose state through shape/motion plus accessibility labels. Do not add a dashboard.

All actions call `AppModel`; never shell out directly from views.
