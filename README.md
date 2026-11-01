# Remote AI

Remote AI is a native macOS companion for persistent Claude Code sessions running on a remote server.

The product surface is intentionally small: a floating pixel-cloud mascot reports connection, synchronization and Claude lifecycle state. OpenSSH, Mutagen and tmux do the infrastructure work underneath; Warp or Terminal is opened only when the developer wants to take over.

## What it does

- keeps code in the normal local project folder
- mirrors the working tree to a remote host with Mutagen `two-way-safe`
- starts or reuses Claude Code inside a named remote tmux session
- survives terminal closure and temporary Mac/network disconnects
- mirrors remote edits back to the Mac after reconnect
- shows `offline`, `connecting`, `syncing`, `thinking`, `waiting`, and `error` through the pixel-cloud mascot
- opens a Warp review layout with local Git changes beside the live Claude tmux session
- sends macOS notifications when Claude is waiting for input

## Build and run

```bash
git clone --recurse-submodules https://github.com/f2re/remote_ai.git
cd remote_ai
swift test
./build.sh --install
open ~/Applications/RemoteAI.app
```

### Dependencies

- macOS 14+
- Swift 6 toolchain
- OpenSSH (built into macOS)
- Mutagen (`brew install mutagen-io/mutagen/mutagen`)
- optional Warp for the preferred review/session handoff
- remote host with `tmux` and the unmodified `claude` CLI installed and authenticated

## Developing Remote AI with BAMA

The macOS agent framework is [BAMA](https://github.com/daveebbelaar/bama), pinned as the `vendor/bama` git submodule. BAMA is not copied into local prompts: its own router and skills are the source of truth.

Start Claude Code with the vendored BAMA plugin:

```bash
./scripts/claude-bama.sh
```

That command initializes the submodule and launches:

```bash
claude --plugin-dir vendor/bama
```

Start product work from `vendor/bama/skills/start/bama/SKILL.md`. The current mascot pass uses `ux-design`, `mac-design`, `design-system`, `design-kit`, `build-and-verify`, and `improve-loop`. See `docs/BAMA-DELEGATION.md` for the work-packet map.

## Design

Remote AI aims for a calm, quiet, confident macOS feel. The custom identity is limited to the pixel-cloud mascot; menus, Settings, notifications and system behavior remain native.

- `design/DESIGN-SYSTEM.md`: app-wide visual and motion rules
- `design/KIT.md`: pixel-cloud component specification
- `docs/BRIEF.md`: product and UX contract
- `docs/GLOSSARY.md`: stable user-facing vocabulary

## SSH identity note

Remote AI can pass an explicit identity file to direct SSH commands. Mutagen itself uses OpenSSH and inherits normal OpenSSH configuration. If the server needs a non-default key, define the host/alias, `User`, `Port`, and `IdentityFile` in `~/.ssh/config` and use that alias as the Remote AI host. This keeps direct SSH and Mutagen on the same route.

## Safety defaults

Remote AI uses Mutagen `two-way-safe`, surfaces synchronization conflicts instead of silently resolving them, keeps `.git` local, uses normal OpenSSH host-key trust, and never reads or stores Claude OAuth/session credentials.

## Development workflow

Feature work goes through a branch + PR, with `swift test`, `swift build`, and app packaging required by macOS CI before merge.
