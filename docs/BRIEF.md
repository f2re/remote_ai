# Remote AI brief

## One sentence

A tiny native macOS mascot that lets a developer start, leave running, reconnect to, and monitor Claude Code on a remote server while the project directory is mirrored back to the Mac.

## Primary user flow

1. First launch: configure one SSH host and choose a local project folder.
2. Remote AI creates/resumes a Mutagen mirror into a per-project remote workspace.
3. Remote AI starts or reuses a named tmux session containing the unmodified `claude` CLI.
4. The mascot changes state without opening a dashboard.
5. When Claude becomes idle or asks for input, macOS sends a notification.
6. The user can close the laptop; the tmux session keeps running remotely.
7. After reconnect, Mutagen resumes and the local tree catches up.

## Mascot states

- offline: sleeping/neutral
- connecting: searching
- syncing: rotating/sweeping motion
- thinking: subtle pulse
- waiting: alert/awake plus notification
- error: warning motion; details only after click

## Scope for MVP

- one configured server
- one active workspace at a time
- SSH key or normal OpenSSH config
- Mutagen mirroring
- tmux Claude lifecycle
- status polling and notifications
- choose project / start / attach / stop / Settings

## Explicit non-goals for MVP

- embedded chat UI
- file editor
- API-key brokerage
- OAuth token proxying
- multi-user server service
- automatic remote deletion
- replacing Claude Code itself

## Done when

A user can select a local repo, start Remote AI, detach, lose connectivity, reconnect, and see the mascot correctly return to syncing/thinking/waiting without losing edits.
