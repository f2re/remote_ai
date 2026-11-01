# Remote AI design system

## Intent

Calm, quiet, confident. The app should feel native to macOS while giving the mascot one distinct identity: a crisp pixel-art cloud.

## System boundary

Use native macOS surfaces for Settings, menus, notifications, alerts, keyboard behavior and accessibility. Custom drawing is reserved for the mascot and its tiny status particles.

## Palette

- Cloud body uses semantic label/background-derived tones that adapt to appearance.
- Cloud outline uses a stronger semantic neutral.
- Status accents use macOS semantic system colors and always pair with expression/shape/motion.
- Avoid fixed white/black in chrome. Avoid decorative gradients.

## Metrics

- Mascot hit area: 76–84 pt.
- Pixel art body: about 60–64 pt wide.
- Pixel unit: integer-scaled at runtime; geometry aligns to whole points.
- Hover changes scale only and never changes layout bounds.
- Floating panel has no visible card background by default.

## Motion

All mascot motion goes through shared motion tokens.

- hover: fast, low-amplitude scale feedback
- state: short cross-state easing
- idle: very slow 1–2 pt vertical drift only for active states
- syncing: small orbiting pixel satellites
- thinking: slow drift plus sparse sparkle
- waiting: static or near-static
- error: no shaking loop; concerned expression plus warning cluster

Reduce Motion disables repeating drift/orbit/sparkle loops. State changes remain visible through static expression and a short opacity transition.

## Surfaces

- Mascot panel: transparent, borderless, nonactivating, draggable by background, floats across Spaces.
- Context menu: native SwiftUI/macOS menu.
- Settings: native Settings scene and Form controls.
- Warp/Terminal handoff: external tools, never embedded in a custom dashboard.

## Typography

The persistent mascot surface has no text. Tooltips, Settings and notifications use system typography only.

## Interaction

- Primary click while offline/error: Start / Reconnect.
- Primary click while active: Open Review in Warp.
- Right click: native context menu.
- Hover: immediate subtle scale/halo; no translation or layout shift.
- VoiceOver reports semantic state, not pixel decoration.

## Accessibility

- Meaning never depends on color alone.
- Keep the mascot implemented as a real `Button`.
- Respect Reduce Motion and Reduce Transparency.
- Keep all tooltip/action words aligned with `docs/GLOSSARY.md`.

## Agent rule

Feature views must not introduce raw mascot colors, radii, scale factors or animation durations. Put them in `Sources/RemoteAI/UI/MascotDesign.swift` first.
