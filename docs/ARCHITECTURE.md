# Architecture

```text
macOS Remote AI
  AppModel / state machine
  ├─ Mascot UI (SwiftUI in floating NSPanel)
  ├─ ConfigStore
  ├─ MutagenController ── OpenSSH transport ── remote workspace
  └─ RemoteRuntimeController ── /usr/bin/ssh ── tmux ── claude
```

## State precedence

`error > offline > connecting > syncing > thinking > waiting`

A sync conflict is an error even if Claude is still running. SSH loss is offline. During initial session setup the state is connecting. Mutagen staging/scanning is syncing. A live Claude pane with active markers is thinking. A live idle pane is waiting.

## Workspace identity

Workspace IDs are deterministic from the standardized local path. The remote directory and tmux session use the same sanitized ID so reconnect does not create duplicates.

## Synchronization safety

Use Mutagen `two-way-safe`. Both the local developer and remote Claude can modify the tree, so conflicts must not be auto-resolved by precedence. Ignore generated/heavy paths such as `.build`, `DerivedData`, `node_modules`, `venv`, `.venv`, `target`, `build`, and `dist` by default. Keep `.git` synchronized only after explicit testing; MVP ignores `.git` to prevent concurrent Git metadata mutation across machines.

## Authentication boundary

Remote AI never implements Claude account login. It launches the unmodified `claude` CLI remotely. If that process requires authentication, the user attaches to that session and completes Anthropic's own flow. Remote AI does not read credential files or receive access tokens.

## Remote command boundary

Local executable + argv is always used for local tools. SSH necessarily invokes a remote shell for tmux commands, so values are sanitized and shell-quoted. Project/session IDs are restricted to ASCII alphanumerics, `_` and `-`.

## Future layers

- isolated Mutagen daemon and app-private SSH wrapper/config
- multiple servers and workspaces
- launch-at-login
- signed/notarized distribution
- richer Claude status integration if a stable machine-readable interface is available
