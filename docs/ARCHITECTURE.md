# Architecture

```text
macOS Remote AI
  AppModel / state machine
  ├─ Mascot UI (SwiftUI in floating NSPanel)
  ├─ ConfigStore
  ├─ MutagenController ── OpenSSH transport ── remote workspace
  └─ RemoteRuntimeController ── /usr/bin/ssh ── tmux ── unmodified claude
                                                   └─ session-only Remote AI status plugin
                                                      └─ lifecycle hook state file
```

## State precedence

`sync conflict/error > offline > connecting > syncing > Claude lifecycle hook > pane fallback`

A sync conflict is an error even if Claude is still running. SSH loss is offline. During initial session setup the state is connecting. Mutagen staging/scanning is syncing. Once sync is healthy, Claude lifecycle events report thinking/waiting/error. A bounded tmux pane parser is retained only as a compatibility fallback when an older Claude Code build does not accept `--plugin-dir`.

## Claude status bridge

Remote AI installs a tiny plugin under `~/.remote-ai/runtime/status-plugin` on the remote host and starts the unmodified Claude Code binary with `--plugin-dir` when supported. The plugin adds lifecycle hooks; it does not replace the user's project/user hooks.

The bridge records only a state token plus Unix timestamp into `~/.remote-ai/state/<workspace>.state`:

- `SessionStart` -> waiting
- `UserPromptSubmit` / `PreToolUse` -> thinking
- `PermissionRequest` / relevant `Notification` -> waiting
- `Stop` -> waiting
- `StopFailure` -> error
- `SessionEnd` -> offline

Hook stdin is discarded. Remote AI does not parse, copy, or persist prompts, tool inputs, responses, transcripts, OAuth tokens, or API keys.

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
- native Claude background-session provider as an alternative to tmux when minimum supported Claude Code version is raised
- multiple servers and workspaces
- launch-at-login
- signed/notarized distribution
