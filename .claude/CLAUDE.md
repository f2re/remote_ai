# Remote AI

Native macOS mascot for supervising a persistent Claude Code session on a remote Linux/macOS host while code stays mirrored locally.

## BAMA agent framework

BAMA is pinned as the `vendor/bama` submodule. Its skills are the source of truth for native macOS product work in this repository.

Initialize it with:

```bash
git submodule update --init --recursive
```

Start every macOS product task at `vendor/bama/skills/start/bama/SKILL.md`. Do not invent a parallel design process when BAMA already has a skill for the work.

For mascot/UI work, execute the BAMA pipeline in this order:

1. `vendor/bama/skills/design/ux-design/SKILL.md`
2. `vendor/bama/skills/design/mac-design/SKILL.md`
3. `vendor/bama/skills/design/design-system/SKILL.md`
4. `vendor/bama/skills/design/design-kit/SKILL.md`
5. `vendor/bama/skills/code/swift-swiftui/SKILL.md`
6. `vendor/bama/skills/ship/build-and-verify/SKILL.md`
7. `vendor/bama/skills/ship/improve-loop/SKILL.md`

The active delegation map lives in `docs/BAMA-DELEGATION.md`. GitHub issues are work packets; each packet names its owning BAMA skill and acceptance criteria.

Design rules: `design/DESIGN-SYSTEM.md`. Use its tokens; never add raw mascot colors, radii, or animation durations to feature views.
Custom mascot rules: `design/KIT.md`.

## Product contract

Remote AI is intentionally quiet. The default UI is one small floating pixel-cloud mascot. It communicates only these states: offline, connecting, syncing, thinking, waiting, and error. Configuration and destructive controls stay behind a context menu or Settings.

Architecture: local Swift app -> OpenSSH + Mutagen -> remote workspace -> tmux -> unmodified Claude Code. Claude keeps working when the Mac sleeps or disconnects. Mutagen catches up on reconnect.

## Non-negotiable invariants

- Never collect, proxy, copy, or persist Claude OAuth/session credentials. Authentication belongs to the unmodified Claude Code process on the remote machine.
- Default sync mode is `two-way-safe`. A conflict is a visible error state, never silently resolved by deleting remote or local edits.
- Never purge a remote workspace until a successful Mutagen flush has completed or the user explicitly forces data loss.
- Build shell commands from escaped arguments. Do not interpolate project paths, prompts, hostnames, or session names into executable shell syntax without validation/quoting.
- SSH host keys use normal OpenSSH trust. Never set `StrictHostKeyChecking=no`.
- Keep the mascot surface minimal. Diagnostics live in logs and Settings.
- Keep native controls native. The mascot may be custom; menus, Settings, alerts and system notifications remain standard macOS surfaces.

## Repository roles

These are routing wrappers around BAMA, not replacements for BAMA skills:

- `orchestrator`: integration, sequencing, acceptance, and choosing the next BAMA skill.
- `macos-ui`: applies BAMA UX/design/SwiftUI skills to the mascot, Settings and notifications.
- `remote-runtime`: SSH, tmux, Claude lifecycle, attach/detach, remote bootstrap.
- `sync-engineer`: Mutagen sessions, conflict detection, local/remote workspace mapping.
- `qa-security`: tests, failure injection, shell/credential review, packaging gates.

## Build gates

```bash
swift build
swift test
./build.sh
```

Every feature must keep state transitions deterministic and testable without a live server. Remote integration tests are opt-in.
