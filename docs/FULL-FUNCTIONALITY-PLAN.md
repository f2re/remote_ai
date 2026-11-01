# Remote AI full-functionality release plan

Target: v0.2.0

Work packets are delegated to the repository-local agents and integrated through one release branch.

1. remote-runtime: deterministic preflight, bounded SSH connection attempts, remote dependency checks, restore an existing tmux/Claude session after app relaunch, actionable error mapping.
2. sync-engineer: route-scoped Mutagen session identity so a host/user/port/root change cannot silently reuse an old synchronization endpoint; preserve two-way-safe and conflict visibility.
3. macos-ui: compact Diagnostics section in native Settings with Test Setup, local/remote readiness rows, and no dashboard expansion.
4. qa-security: unit coverage for routing/session identity/preflight parsing, release verification, CI artifacts, and tag release guards.

Release acceptance:
- first launch guides the user to Settings and project selection;
- configured launches restore status without starting a second Claude process;
- Start/Reconnect validates local and remote prerequisites before creating sync/runtime state;
- SSH failures return in bounded time and are actionable;
- Mutagen never reuses a session created for a different remote route;
- sync conflicts remain blocking and visible;
- tests, release build, app packaging, light/dark snapshots, release verification all pass on macOS CI;
- v0.2.0 artifacts include app ZIP, screenshots, checksums, and individual PNGs;
- unsigned/not-notarized builds remain prerelease; Developer ID + notarization automatically promote a tag build to a normal release.
