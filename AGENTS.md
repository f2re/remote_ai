# Remote AI

Native macOS mascot for supervising a persistent Claude Code session on a remote Linux/macOS host while code stays mirrored locally.

## Agent framework

BAMA is pinned at `vendor/bama`. Initialize it with:

```bash
git submodule update --init --recursive
```

Before changing native macOS code, read the relevant BAMA skill. Start with `vendor/bama/skills/start/bama/SKILL.md`. For this repository the common skills are `new-mac-app`, `swift-swiftui`, `os-integrations`, `mac-design`, `build-and-verify`, and `test-mac-app`.

## Product contract

Remote AI is intentionally quiet. The default UI is one small floating mascot. It communicates only these states: offline, connecting, syncing, thinking, waiting, and error. Configuration and destructive controls stay behind a context menu or Settings.

Architecture: local Swift app -> OpenSSH + Mutagen -> remote workspace -> tmux -> unmodified Claude Code. Claude keeps working when the Mac sleeps or disconnects. Mutagen catches up on reconnect.

## Non-negotiable invariants

- Never collect, proxy, copy, or persist Claude OAuth/session credentials. Authentication belongs to the unmodified Claude Code process on the remote machine.
- Default sync mode is `two-way-safe`. A conflict is a visible error state, never silently resolved by deleting remote or local edits.
- Never purge a remote workspace until a successful Mutagen flush has completed or the user explicitly forces data loss.
- Build shell commands from escaped arguments. Do not interpolate project paths, prompts, hostnames, or session names into executable shell syntax without validation/quoting.
- SSH host keys use normal OpenSSH trust. Never set `StrictHostKeyChecking=no`.
- Keep the mascot surface minimal. Diagnostics live in logs and Settings.

## Roles

- `orchestrator`: owns architecture, integration, sequencing, and acceptance.
- `macos-ui`: owns AppKit/SwiftUI mascot, menu, Settings, notifications, accessibility.
- `remote-runtime`: owns SSH, tmux, Claude lifecycle, attach/detach, remote bootstrap.
- `sync-engineer`: owns Mutagen sessions, conflict detection, local/remote workspace mapping.
- `qa-security`: owns tests, failure injection, shell/credential review, packaging gates.

## Build gates

```bash
swift build
swift test
```

Every feature must keep state transitions deterministic and testable without a live server. Remote integration tests are opt-in.
