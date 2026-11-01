import Foundation

struct MutagenController: Sendable {
    private let runner = ProcessRunner()

    func ensureSession(workspace: Workspace, config: RemoteAIConfig) async throws {
        let executable = try await mutagenExecutable()
        _ = try? await runner.run(executable: executable, arguments: ["daemon", "start"])

        let existing = try await runner.run(executable: executable, arguments: ["sync", "list", workspace.id])
        if existing.exitCode == 0, existing.stdout.contains("Name: \(workspace.id)") {
            let resumed = try await runner.run(executable: executable, arguments: ["sync", "resume", workspace.id])
            guard resumed.exitCode == 0 else {
                throw RemoteAIError.commandFailed(resumed.combinedOutput)
            }
            return
        }

        var arguments = [
            "sync", "create",
            "--name=\(workspace.id)",
            "--sync-mode=two-way-safe"
        ]
        for ignored in RemoteAIConfig.defaultIgnores {
            arguments.append("--ignore=\(ignored)")
        }
        arguments += [workspace.localPath, endpoint(workspace: workspace, config: config)]

        let created = try await runner.run(executable: executable, arguments: arguments)
        guard created.exitCode == 0 else {
            throw RemoteAIError.commandFailed(created.combinedOutput)
        }
    }

    func flush(workspace: Workspace) async throws {
        let executable = try await mutagenExecutable()
        let result = try await runner.run(executable: executable, arguments: ["sync", "flush", workspace.id])
        guard result.exitCode == 0 else {
            throw RemoteAIError.commandFailed(result.combinedOutput)
        }
    }

    func pause(workspace: Workspace) async {
        guard let executable = try? await mutagenExecutable() else { return }
        _ = try? await runner.run(executable: executable, arguments: ["sync", "pause", workspace.id])
    }

    func status(workspace: Workspace) async -> SyncHealth {
        guard let executable = try? await mutagenExecutable() else {
            return .missing
        }
        guard let result = try? await runner.run(executable: executable, arguments: ["sync", "list", workspace.id]) else {
            return .unavailable("Mutagen status command failed")
        }
        guard result.exitCode == 0, result.stdout.contains("Name: \(workspace.id)") else {
            return .missing
        }
        return MutagenStatusParser.parse(result.stdout)
    }

    func endpoint(workspace: Workspace, config: RemoteAIConfig) -> String {
        let port = config.port == 22 ? "" : ":\(config.port)"
        return "\(config.user)@\(config.host)\(port):\(workspace.remotePath)"
    }

    private func mutagenExecutable() async throws -> String {
        let result = try await runner.run(executable: "/usr/bin/which", arguments: ["mutagen"])
        let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard result.exitCode == 0, !path.isEmpty else {
            throw RemoteAIError.dependencyMissing("Mutagen is not installed. Install it with Homebrew: brew install mutagen-io/mutagen/mutagen")
        }
        return path
    }
}

struct MutagenStatusParser {
    static func parse(_ output: String) -> SyncHealth {
        let lower = output.lowercased()
        if lower.contains("conflict") {
            return .conflict("Mutagen reports a synchronization conflict")
        }
        if lower.contains("paused") {
            return .paused
        }
        if lower.contains("watching for changes") {
            return .ready
        }
        let activeWords = ["scanning", "staging", "reconcil", "transition", "propagating"]
        if activeWords.contains(where: lower.contains) {
            let status = output.split(separator: "\n").first { $0.contains("Status:") }.map(String.init) ?? "Synchronizing"
            return .syncing(status)
        }
        if lower.contains("unable to connect") || lower.contains("disconnected") {
            return .unavailable("Mutagen cannot reach the remote endpoint")
        }
        return .ready
    }
}
