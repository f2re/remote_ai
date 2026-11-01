# Remote AI stories

BAMA backlog for the floating pixel-cloud interface. Each story is small enough for one implementation commit and maps to the delegated work packets in `docs/BAMA-DELEGATION.md`.

## M1 — Pixel-cloud core loop

### S-001 Define the mascot interaction language
As the user, I can understand what the mascot means and what a click will do without opening a dashboard.
Depends: none
Issue: #8 (`ux-design`)
Acceptance:
- [manual] The brief defines one primary flow from offline to waiting and takeover in Warp.
- [manual] All six states have a distinct expression/shape/motion description, not color alone.
- [manual] Button, tooltip, context-menu, Settings and accessibility words use the glossary vocabulary.
- [manual] No new modal, dashboard or permanent status label is introduced.
Status: done

UX:
- Flow: click sleeping cloud -> connect/sync/start -> thinking -> waiting + notification -> click cloud -> Warp review/session.
- Surface: borderless floating companion panel; configuration remains in native Settings.
- Access: real Button, VoiceOver semantic state, right-click actions, Reduce Motion static fallbacks.

### S-002 Define the visual system and mascot kit
As the user, I see a quiet native macOS companion with one recognizable custom identity.
Depends: S-001
Issue: #9 (`mac-design`, `design-system`)
Acceptance:
- [manual] `design/DESIGN-SYSTEM.md` defines metrics, semantic palette, motion and accessibility rules.
- [manual] `design/KIT.md` defines deterministic pixel-cloud geometry and every state expression.
- [manual] Custom drawing is limited to mascot/status pixels; menus, Settings and notifications remain native.
- [manual] Mascot view code uses shared tokens instead of raw animation durations, radii or status colors.
Status: done

### S-003 Render a state-driven pixel-cloud mascot
As the user, I can recognize offline, connecting, syncing, thinking, waiting and error states at a glance.
Depends: S-002
Issue: #10 (`design-kit`, `macos-ui`)
Acceptance:
- [unit] Every `MascotState` maps deterministically to a face, indicator and motion policy.
- [snap] The cloud silhouette is code-driven pixel geometry, not an SF Symbol placeholder.
- [snap] All six states differ by expression and/or indicator geometry; status color is only reinforcement.
- [snap] Hover and press scale inside a fixed 80 pt hit area without layout shift or clipping.
- [manual] Right-click context actions and primary click behavior remain unchanged.
Status: doing

### S-004 Respect motion and accessibility preferences
As a keyboard/VoiceOver/Reduce Motion user, I can operate the mascot without losing state meaning.
Depends: S-003
Issue: #10 (`design-kit`, `macos-ui`)
Acceptance:
- [snap] Reduce Motion disables repeating orbit/float/search/sparkle loops while expressions remain distinct.
- [manual] VoiceOver announces the semantic state and primary action hint, not decorative pixel details.
- [manual] Context actions remain available without relying on hover.
- [snap] Light and dark appearances preserve cloud/face contrast.
Status: doing

## M2 — Verify and harden

### S-005 Verify mascot build, packaging and regressions
As the maintainer, I can change the mascot without breaking remote runtime behavior.
Depends: S-003, S-004
Issue: #11 (`build-and-verify`, `improve-loop`, `test-mac-app`)
Acceptance:
- [unit] `swift test` passes.
- [self] `swift build` passes on macOS CI.
- [self] `./build.sh` packages the app on macOS CI.
- [manual] Panel remains draggable, floating across Spaces and full-screen auxiliary mode.
- [unit] SSH/Mutagen/tmux state tests remain unchanged and passing.
Status: todo

### S-006 Add an agent-reviewable snapshot mode
As the UI/QA agents, we can render mascot states and Settings in light/dark mode without a live remote server.
Depends: S-005
Issue: follow-up after #11
Acceptance:
- [self] A snapshot command can force each of the six mascot states without SSH/Mutagen/tmux.
- [snap] It emits light and dark PNGs for every mascot state plus Settings.
- [self] Snapshot mode exits deterministically and is documented for agents.
Status: todo

## Later

- Multiple simultaneous remote workspaces and one mascot per workspace.
- User-selectable mascot skins or themes.
- Rich progress/history dashboard.
- Embedded terminal or chat UI.

## Done when

M1 is complete when the pixel cloud replaces the placeholder, its six states remain readable with Reduce Motion enabled, and the existing primary/context actions still drive the same `AppModel` methods. M2 is complete when CI/build/package checks pass and agents have deterministic snapshots for future improve loops.
