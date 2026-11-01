import Foundation

struct RemoteRuntimeController: Sendable {
    private let ssh = SSHController()

    func prepare(workspace: Workspace, config: RemoteAIConfig) async throws {
        try config.validate()
        let path = RemotePath.shellExpression(workspace.remotePath)
        let command = "command -v tmux >/dev/null 2>&1 || { echo 'tmux is not installed'; exit 41; }; command -v claude >/dev/null 2>&1 || { echo 'claude is not installed'; exit 42; }; mkdir -p -- \(path)"
        _ = try await ssh.run(remoteCommand: command, config: config)
    }

    func startClaude(workspace: Workspace, config: RemoteAIConfig) async throws {
        let session = Shell.quote(workspace.sessionName)
        let path = RemotePath.shellExpression(workspace.remotePath)
        let command = "tmux has-session -t \(session) 2>/dev/null || tmux new-session -d -s \(session) -c \(path) claude"
        _ = try await ssh.run(remoteCommand: command, config: config)
    }

    func poll(workspace: Workspace, config: RemoteAIConfig) async throws -> RuntimeSnapshot {
        let session = Shell.quote(workspace.sessionName)
        let command = "if tmux has-session -t \(session) 2>/dev/null; then printf '__RA_SESSION__=1\\n'; tmux capture-pane -p -t \(session) -S -60; else printf '__RA_SESSION__=0\\n'; fi"
        let result = try await ssh.run(remoteCommand: command, config: config)
        let exists = result.stdout.contains("__RA_SESSION__=1")
        let pane = result.stdout
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.hasPrefix("__RA_SESSION__=") }
            .joined(separator: "\n")
        return RuntimeSnapshot(sessionExists: exists, pane: pane)
    }

    func stopClaude(workspace: Workspace, config: RemoteAIConfig) async throws {
        let session = Shell.quote(workspace.sessionName)
        _ = try await ssh.run(remoteCommand: "tmux kill-session -t \(session) 2>/dev/null || true", config: config)
    }

    func attachCommand(workspace: Workspace, config: RemoteAIConfig) -> String {
        let remote = "tmux attach-session -t \(Shell.quote(workspace.sessionName))"
        return ssh.interactiveShellCommand(remoteCommand: remote, config: config)
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
