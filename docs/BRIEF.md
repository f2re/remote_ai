# Remote AI brief

## One sentence

A tiny native macOS pixel-cloud mascot that lets a developer start, leave running, reconnect to, and monitor Claude Code on a remote server while the project directory is mirrored back to the Mac.

## Primary user flow

1. First launch: configure one SSH host and choose a local project folder.
2. Remote AI creates/resumes a Mutagen mirror into a per-project remote workspace.
3. Remote AI starts or reuses a named tmux session containing the unmodified `claude` CLI.
4. The pixel-cloud mascot changes expression and motion without opening a dashboard.
5. When Claude becomes idle or asks for input, macOS sends a notification.
6. Click the active mascot or notification to open the Warp review/session handoff.
7. The user can close the laptop; the tmux session keeps running remotely.
8. After reconnect, Mutagen resumes and the local tree catches up.

## Design plan

- Archetype: floating companion panel plus native Settings.
- Information architecture: no primary window; mascot is the only persistent product surface. Settings contains configuration only.
- Command map: primary click starts/reconnects while offline/error; primary click opens Warp while active. Context menu exposes Choose Project, Start/Reconnect, Open Review in Warp, Attach in Terminal, Stop, Settings, Quit.
- Empty state: sleeping cloud with tooltip directing the first project/server setup.
- Feeling: calm, quiet, confident.
- Customization boundary: the cloud and its tiny status particles are custom. Menus, Settings, notifications, buttons and alerts stay native.

## Mascot UX

Flow: click sleeping cloud -> connect/sync/start -> cloud becomes active -> Claude works -> cloud thinks -> Claude waits -> cloud settles awake + macOS notification -> click cloud/notification -> Warp opens local review + live tmux session.

Surface: a borderless floating panel. No dashboard, popover stack or permanent text.

States:
- offline: sleeping face, low emphasis, no looped motion
- connecting: awake/searching face, one moving status pixel
- syncing: awake face, two orbiting pixel satellites
- thinking: focused face, gentle float and sparkle
- waiting: calm awake face, one steady status pixel
- error: concerned face and compact warning pixel cluster; details remain in tooltip/context interaction

Words:
- `Choose Project…`
- `Start / Reconnect`
- `Open Review in Warp`
- `Attach in Terminal`
- `Stop`
- `Settings…`
- `Quit`

Access:
- the mascot remains a real `Button`
- VoiceOver reads the semantic state, not the decorative pixels
- right-click context menu exposes all actions
- Reduce Motion removes orbit/float loops and keeps static state expressions
- status meaning never depends on color alone

## Scope for MVP

- one configured server
- one active workspace at a time
- SSH key or normal OpenSSH config
- Mutagen mirroring
- tmux Claude lifecycle
- status polling and notifications
- choose project / start / attach / stop / Settings
- Warp review handoff
- polished pixel-cloud mascot

## Explicit non-goals for MVP

- embedded chat UI
- file editor
- API-key brokerage
- OAuth token proxying
- multi-user server service
- automatic remote deletion
- replacing Claude Code itself
- dashboard-style monitoring UI

## Done when

A user can select a local repo, start Remote AI, detach, lose connectivity, reconnect, and see the mascot correctly return to syncing/thinking/waiting without losing edits. The cloud is legible in light/dark mode, respects Reduce Motion, and opens the same Warp session when the user needs to take over.
