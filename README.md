# Remote AI

<p align="center">
  <img src="Resources/AppIcon.svg" width="144" alt="Remote AI pixel-cloud app icon">
</p>

Remote AI is a native macOS companion for persistent Claude Code sessions running on a remote server.

The product surface is intentionally small: a floating pixel-cloud mascot reports connection, synchronization and Claude lifecycle state. OpenSSH, Mutagen and tmux do the infrastructure work underneath; Warp or Terminal is opened only when the developer wants to take over.

## What it does

- keeps code in the normal local project folder
- mirrors the working tree to a remote host with Mutagen `two-way-safe`
- scopes every Mutagen session to the effective host/user/port/remote path so changing servers cannot silently reuse an old route
- starts or reuses Claude Code inside a named remote tmux session
- restores an already-running session after the macOS app is relaunched without starting a duplicate Claude process
- survives terminal closure and temporary Mac/network disconnects
- mirrors remote edits back to the Mac after reconnect
- shows `offline`, `connecting`, `syncing`, `thinking`, `waiting`, and `error` through the pixel-cloud mascot
- opens a Warp review layout with local Git changes beside the live Claude tmux session
- sends macOS notifications when Claude is waiting for input
- provides a non-destructive **Test Setup** check for local project access, SSH identity, Mutagen, SSH connectivity, remote tmux and Claude Code

## Build and run

```bash
git clone --recurse-submodules https://github.com/f2re/remote_ai.git
cd remote_ai
swift test
./build.sh --install
open ~/Applications/RemoteAI.app
```

Release builds are Universal 2 (`arm64` + `x86_64`). Use `./build.sh --debug` for a native-architecture debug bundle or `./build.sh --open` to install and relaunch the current release build.

### Dependencies

- macOS 14+
- Swift 6 toolchain for source builds
- OpenSSH (built into macOS)
- Mutagen (`brew install mutagen-io/mutagen/mutagen`)
- optional Warp for the preferred review/session handoff
- remote host with `tmux` and the unmodified `claude` CLI installed and authenticated

After entering the server and project in Settings, run **Test Setup**. It is read-only and does not create a synchronization session or start Claude Code. **Start / Reconnect** repeats the preflight before changing remote state.

## SSH identity and route behavior

Remote AI uses normal OpenSSH host-key trust and bounded non-interactive SSH probes. Leave **SSH key path** empty to use `~/.ssh/config`, `ssh-agent`, or OpenSSH default identities.

An explicit key path is supported for Remote AI's direct SSH commands. Mutagen uses OpenSSH discovery itself, so for a non-default key also set `IdentityFile` for the host/alias in `~/.ssh/config`. The Settings diagnostic reports this as a warning instead of pretending the two transports are configured identically.

Custom ports use Mutagen's documented `[user@]host[:port]:path` SSH endpoint syntax.

## Screenshots

Release screenshots are generated from the real SwiftUI views in light and dark appearance:

```bash
./tools/snap.sh
```

`./tools/verify-release.sh` then verifies the application bundle, Universal 2 architectures, codesign integrity, bundle metadata and the complete 16-image screenshot set.

CI publishes the application ZIP, screenshot ZIP, checksums and individual PNGs as one verified workflow artifact. Version-tag releases attach the same materials to GitHub Releases.

## Releases

Every push/PR runs tests, release compilation, Universal 2 app packaging, deterministic screenshots and release-bundle verification. Pushing a `v*` tag that points to a commit contained in `main` runs the release pipeline and creates a GitHub Release.

The pipeline supports optional Developer ID signing and Apple notarization. Without signing/notarization secrets it publishes an ad-hoc signed **prerelease** for development/testing. With all Apple credentials configured, the same tag workflow signs, notarizes, staples, Gatekeeper-verifies and publishes a normal release. See `docs/RELEASE.md`.

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

Start product work from `vendor/bama/skills/start/bama/SKILL.md`. The current work uses the repository-local `remote-runtime`, `sync-engineer`, `macos-ui`, and `qa-security` agents, with BAMA `build-and-verify`, `test-mac-app`, and `improve-loop` as the release gates. See `docs/BAMA-DELEGATION.md` and `docs/FULL-FUNCTIONALITY-PLAN.md`.

## Design

Remote AI aims for a calm, quiet, confident macOS feel. The custom identity is limited to the pixel-cloud mascot; menus, Settings, notifications and system behavior remain native.

- `design/DESIGN-SYSTEM.md`: app-wide visual and motion rules
- `design/KIT.md`: pixel-cloud component specification
- `docs/BRIEF.md`: product and UX contract
- `docs/GLOSSARY.md`: stable user-facing vocabulary

## Safety defaults

Remote AI uses Mutagen `two-way-safe`, surfaces synchronization conflicts instead of silently resolving them, pauses stale route sessions instead of deleting them, keeps `.git` local, uses normal OpenSSH host-key trust, and never reads or stores Claude OAuth/session credentials.

## Development workflow

Feature work goes through a branch + PR. macOS CI must pass tests, release compilation, Universal 2 packaging, codesign verification and light/dark screenshot gates before merge.
