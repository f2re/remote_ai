# Delegated MVP backlog

The orchestrator owns integration. These are independent work packages for Claude Code subagents.

## macos-ui

Build the accessory app lifecycle, transparent floating `NSPanel`, mascot states, drag/reposition behavior, context menu, Settings, and notification permission. Acceptance: no normal document window appears; VoiceOver has a state label; user can choose a folder and trigger start/stop through `AppModel`.

## remote-runtime

Build SSH reachability, remote workspace creation, tmux start/reuse/kill, bounded pane capture, and attach command generation. Acceptance: all user-derived remote values are quoted/sanitized; a missing tmux/claude binary returns a typed error; one poll uses one SSH round trip.

## sync-engineer

Build Mutagen dependency detection, create/resume/flush/terminate, endpoint generation, ignore list, and conflict/status parsing. Acceptance: default mode is `two-way-safe`; conflict maps to an error; port syntax follows Mutagen SSH endpoint rules; `.git` is ignored in MVP.

## qa-security

Add pure tests for parser and quoting/workspace ID helpers, review credential boundaries, and create a manual failure-injection checklist. Acceptance: `swift test` does not require SSH/Mutagen and catches active/waiting/conflict classifications.

## orchestrator

Integrate the four packages, remove duplicate status probes, ensure state precedence, and prepare the first runnable `.app` build script. Acceptance: `swift build && swift test`; README setup path is sufficient for a new Mac.
