# Changelog

## 0.2.0

Full-functionality hardening release.

- non-destructive setup diagnostics for configuration, local project, SSH identity, Mutagen, SSH connectivity, remote tmux, and remote Claude Code
- bounded SSH connection attempts with actionable authentication/DNS/timeout/refusal/host-key errors
- remote commands run through the remote login shell so user-installed `claude` binaries are discovered consistently
- automatic status restore for an already-running remote tmux/Claude session when Remote AI relaunches
- Start / Reconnect performs preflight before creating or mutating synchronization/runtime state
- Mutagen session identity now includes host, user, port, and remote path; stale/legacy sessions are paused instead of deleted
- robust Mutagen discovery for Homebrew on Apple Silicon and Intel macOS
- Universal 2 release binaries (`arm64` + `x86_64`)
- CI verifies tests, release compile, app bundle, codesign, architectures, metadata, screenshots, ZIP integrity, and checksums
- release tags must point to commits contained in `main`
- release assets include the app ZIP, screenshot ZIP, SHA-256 manifest, and individual light/dark PNGs
- Developer ID + notarization remains optional; unnotarized builds are automatically prereleases

## 0.1.0

Initial Remote AI preview.

- native macOS floating pixel-cloud mascot
- six deterministic runtime states: offline, connecting, syncing, thinking, waiting, error
- OpenSSH + tmux lifecycle for persistent remote Claude Code
- Mutagen `two-way-safe` workspace mirroring and conflict surfacing
- Claude lifecycle status hooks with bounded tmux fallback parsing
- Warp two-pane handoff for local Git review plus live remote Claude session
- macOS notifications that return to the active Warp workspace
- BAMA-driven macOS design and development workflow
- first-run Settings/project setup flow
- generated macOS pixel-cloud application icon
- light/dark release screenshot harness
- CI test/build/package/screenshot gates
- tag-driven GitHub Release workflow with optional Developer ID signing and notarization
