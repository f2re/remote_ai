import Foundation

struct RemoteRuntimeController: Sendable {
    private let ssh = SSHController()

    private static let pluginRoot = ".remote-ai/runtime/status-plugin"
    private static let stateRoot = ".remote-ai/state"

    func prepare(workspace: Workspace, config: RemoteAIConfig) async throws {
        try config.validate()
        let path = RemotePath.shellExpression(workspace.remotePath)
        let plugin = RemotePath.shellExpression(Self.pluginRoot)
        let stateRoot = RemotePath.shellExpression(Self.stateRoot)
        let manifestPath = "\(plugin)/.claude-plugin/plugin.json"
        let hooksPath = "\(plugin)/hooks/hooks.json"
        let scriptPath = "\(plugin)/scripts/state.sh"

        let command = [
            "command -v tmux >/dev/null 2>&1 || { echo 'tmux is not installed'; exit 41; }",
            "command -v claude >/dev/null 2>&1 || { echo 'claude is not installed'; exit 42; }",
            "mkdir -p -- \(path) \(plugin)/.claude-plugin \(plugin)/hooks \(plugin)/scripts \(stateRoot)",
            "printf %s \(Shell.quote(Self.monitorPluginManifest)) > \(manifestPath)",
            "printf %s \(Shell.quote(Self.monitorHooks)) > \(hooksPath)",
            "printf %s \(Shell.quote(Self.monitorScript)) > \(scriptPath)",
            "chmod 700 \(scriptPath)"
        ].joined(separator: "; ")

        _ = try await ssh.run(remoteCommand: command, config: config)
    }

    func startClaude(workspace: Workspace, config: RemoteAIConfig) async throws {
        let session = Shell.quote(workspace.sessionName)
        let path = RemotePath.shellExpression(workspace.remotePath)
        let plugin = RemotePath.shellExpression(Self.pluginRoot)
        let stateFile = RemotePath.shellExpression(stateFilePath(workspace: workspace))

        let launch = "if claude --plugin-dir \(plugin) --version >/dev/null 2>&1; then export REMOTE_AI_STATE_FILE=\(stateFile); exec claude --plugin-dir \(plugin); else exec claude; fi"
        let command = "tmux has-session -t \(session) 2>/dev/null || tmux new-session -d -s \(session) -c \(path) \(Shell.quote(launch))"
        _ = try await ssh.run(remoteCommand: command, config: config)
    }

    func poll(workspace: Workspace, config: RemoteAIConfig) async throws -> RuntimeSnapshot {
        let session = Shell.quote(workspace.sessionName)
        let stateFile = RemotePath.shellExpression(stateFilePath(workspace: workspace))
        let command = "if tmux has-session -t \(session) 2>/dev/null; then printf '__RA_SESSION__=1\\n'; if [ -f \(stateFile) ]; then printf '__RA_STATE__='; cat \(stateFile); fi; tmux capture-pane -p -t \(session) -S -60; else printf '__RA_SESSION__=0\\n'; fi"
        let result = try await ssh.run(remoteCommand: command, config: config)
        let exists = result.stdout.contains("__RA_SESSION__=1")
        let stateLine = result.stdout
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .first { $0.hasPrefix("__RA_STATE__=") }
        let reportedState = stateLine.flatMap(HookStateParser.state(fromMarkerLine:))
        let pane = result.stdout
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.hasPrefix("__RA_SESSION__=") && !$0.hasPrefix("__RA_STATE__=") }
            .joined(separator: "\n")
        return RuntimeSnapshot(sessionExists: exists, pane: pane, reportedState: reportedState)
    }

    func stopClaude(workspace: Workspace, config: RemoteAIConfig) async throws {
        let session = Shell.quote(workspace.sessionName)
        _ = try await ssh.run(remoteCommand: "tmux kill-session -t \(session) 2>/dev/null || true", config: config)
    }

    func attachCommand(workspace: Workspace, config: RemoteAIConfig) -> String {
        let remote = "tmux attach-session -t \(Shell.quote(workspace.sessionName))"
        return ssh.interactiveShellCommand(remoteCommand: remote, config: config)
    }

    private func stateFilePath(workspace: Workspace) -> String {
        "\(Self.stateRoot)/\(workspace.id).state"
    }

    private static let monitorPluginManifest = #"{"name":"remote-ai-status","displayName":"Remote AI Status","version":"0.1.0","description":"Local status bridge for the Remote AI macOS mascot","author":{"name":"Remote AI"}}"#

    private static let monitorHooks = #"{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["waiting"],"timeout":2}]}],"UserPromptSubmit":[{"hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["thinking"],"timeout":2}]}],"PreToolUse":[{"matcher":"*","hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["thinking"],"timeout":2}]}],"PermissionRequest":[{"matcher":"*","hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["waiting"],"timeout":2}]}],"Notification":[{"matcher":"permission_prompt|idle_prompt|agent_needs_input|agent_completed","hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["waiting"],"timeout":2}]}],"Stop":[{"hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["waiting"],"timeout":2}]}],"StopFailure":[{"hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["error"],"timeout":2}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh","args":["offline"],"timeout":2}]}]}}"#

    private static let monitorScript = #"#!/usr/bin/env bash
set -u
cat >/dev/null || true
state="${1:-waiting}"
file="${REMOTE_AI_STATE_FILE:-}"
[[ -n "$file" ]] || exit 0
mkdir -p "$(dirname "$file")"
umask 077
tmp="${file}.tmp.$$"
printf "%s|%s\n" "$state" "$(date +%s)" > "$tmp"
mv -f "$tmp" "$file"
exit 0
"#
}

struct HookStateParser {
    static func state(fromMarkerLine line: String) -> MascotState? {
        guard line.hasPrefix("__RA_STATE__=") else { return nil }
        let payload = line.dropFirst("__RA_STATE__=".count)
        let token = payload.split(separator: "|", maxSplits: 1).first.map(String.init)
        switch token {
        case "thinking": return .thinking
        case "waiting": return .waiting
        case "offline": return .offline
        case "error": return .error("Claude Code reported a turn failure")
        default: return nil
        }
    }
}

struct PaneStatusParser {
    private static let activeMarkers = [
        "esc to interrupt",
        "ctrl+c to interrupt",
        "thinking",
        "running",
        "working…",
        "working..."
    ]

    private static let inputMarkers = [
        "do you want to proceed",
        "allow this",
        "press enter",
        "waiting for input",
        "yes, and don't ask"
    ]

    static func state(from pane: String) -> MascotState {
        let lines = pane
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        let tail = lines.suffix(18).joined(separator: "\n").lowercased()

        if activeMarkers.contains(where: tail.contains) {
            return .thinking
        }
        if inputMarkers.contains(where: tail.contains) {
            return .waiting
        }
        return .waiting
    }

    static func lastMeaningfulLine(from pane: String) -> String? {
        pane.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .last { !$0.isEmpty && !$0.hasPrefix("__RA_") }
    }
}
