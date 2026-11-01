# Remote AI full-functionality release plan

Target: v0.2.0

Work packets are delegated to the repository-local agents and integrated through one release branch.

1. `remote-runtime` — deterministic preflight, bounded SSH connection attempts, remote dependency checks, restore an existing tmux/Claude session after app relaunch, actionable error mapping. Tracking: #17.
2. `sync-engineer` — route-scoped Mutagen session identity so a host/user/port/root change cannot silently reuse an old synchronization endpoint; preserve two-way-safe and conflict visibility. Tracking: #18.
3. `macos-ui` — compact Diagnostics section in native Settings with Test Setup, local/remote readiness rows, and no dashboard expansion. Tracking: #19.
4. `qa-security` — unit coverage for routing/session identity/preflight parsing, Universal 2 packaging, release verification, CI artifacts, and tag release guards. Tracking: #20.

Release acceptance:
- first launch guides the user to Settings and project selection;
- configured launches restore status without starting a second Claude process;
- Start/Reconnect validates local and remote prerequisites before creating sync/runtime state;
- SSH failures return in bounded time and are actionable;
- Mutagen never reuses a session created for a different remote route;
- stale synchronization sessions are paused, not deleted;
- sync conflicts remain blocking and visible;
- tests, release build, Universal 2 app packaging, light/dark snapshots, codesign, archive and checksum verification all pass on macOS CI;
- v0.2.0 artifacts include app ZIP, screenshots, checksums, and individual PNGs;
- release tags must refer to commits contained in `main`;
- unsigned/not-notarized builds remain prerelease; Developer ID + notarization automatically promote a tag build to a normal release.

Status: implementation complete on `feat/full-functionality-v0.2.0`; release is gated on macOS CI and final PR verification.
