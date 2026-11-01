# Pixel Cloud design kit

## Feel

Calm. Crisp. Alive.

## Component: PixelCloudMascot

Purpose: the one persistent visual identity and state control for Remote AI.

### Geometry

- deterministic pixel grid rendered in SwiftUI code
- cloud body uses a compact 16-column silhouette with a soft, slightly asymmetrical top and stable flat lower mass
- eyes/mouth are separate state pixels so expressions change without redrawing the silhouette
- status particles sit outside the face and never overlap the hit target edge
- no SF Symbol may replace the cloud body

### State expressions

- offline: closed horizontal eyes; muted body
- connecting: open eyes; one traveling/search pixel
- syncing: open eyes; two orbiting satellites
- thinking: focused eyes; one sparkle and subtle float
- waiting: open relaxed eyes; tiny smile/steady status pixel
- error: concerned eyes/mouth; compact warning cluster

### Interaction states

- rest: full-size cloud, transparent surrounding panel
- hover: slight scale-up plus optional faint system-material halo
- pressed: slight scale-down, no bounce
- disabled: not used for the primary mascot; unavailable actions are disabled in the context menu instead

### Motion

Use `MascotDesign.Motion` only. Repeating motion must stop under Reduce Motion.

### Accessibility

The decorative renderer is hidden from accessibility. `MascotView` exposes one button with the state-specific label from `MascotState.accessibilityLabel`.

## Component: StatusPixels

Purpose: reinforce state without relying on color.

- connecting: one moving square
- syncing: two squares in an orbit
- thinking: four-pixel sparkle
- waiting: one steady square
- error: exclamation-like two/three-pixel cluster
- offline: absent

## Native parts

Context menu, Settings, system notifications and external Warp/Terminal handoff remain native. They are not re-skinned.
