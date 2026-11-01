import Foundation

struct MutagenController: Sendable {
    private let runner = ProcessRunner()

    func sessionName(workspace: Workspace, config: RemoteAIConfig) -> String {
        let route = "\(config.user)@\(config.host):\(config.port)|\(workspace.remotePath)"
        let routeHash = String(StableHash.fnv1a64(route).prefix(10))
        let workspacePart = String(workspace.id.prefix(40))
        return "rai-\(workspacePart)-\(routeHash)"
    }

    func ensureSession(workspace: Workspace, config: RemoteAIConfig) async throws {
        let executable = try await ToolLocator.mutagenExecutable(runner: runner)
        _ = try? await runner.run(executable: executable, arguments: ["daemon", "start"])

        let desiredName = sessionName(workspace: workspace, config: config)
        let listing = try await runner.run(executable: executable, arguments: ["sync", "list"])
        guard listing.exitCode == 0 else {
            throw RemoteAIError.commandFailed(listing.combinedOutput)
        }

        let existingNames = MutagenSessionListParser.names(from: listing.stdout)
        if existingNames.contains(desiredName) {
            let resumed = try await runner.run(executable: executable, arguments: ["sync", "resume", desiredName])
            guard resumed.exitCode == 0 else {
                throw RemoteAIError.commandFailed(resumed.combinedOutput)
            }
            return
        }

        let staleNames = existingNames.filter { name in
            name == workspace.id || (name.hasPrefix(routeSessionPrefix(workspace: workspace)) && name != desiredName)
        }
        for staleName in staleNames {
            let paused = try await runner.run(executable: executable, arguments: ["sync", "pause", staleName])
            guard paused.exitCode == 0 else {
                throw RemoteAIError.commandFailed(
                    "Не удалось приостановить устаревшую сессию Mutagen \(staleName) перед сменой маршрута. \(paused.combinedOutput)"
                )
            }
        }

        var arguments = [
            "sync", "create",
            "--name=\(desiredName)",
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

    func flush(workspace: Workspace, config: RemoteAIConfig) async throws {
        let executable = try await ToolLocator.mutagenExecutable(runner: runner)
        let result = try await runner.run(
            executable: executable,
            arguments: ["sync", "flush", sessionName(workspace: workspace, config: config)]
        )
        guard result.exitCode == 0 else {
            throw RemoteAIError.commandFailed(result.combinedOutput)
        }
    }

    func pause(workspace: Workspace, config: RemoteAIConfig) async {
        guard let executable = try? await ToolLocator.mutagenExecutable(runner: runner) else { return }
        _ = try? await runner.run(
            executable: executable,
            arguments: ["sync", "pause", sessionName(workspace: workspace, config: config)]
        )
    }

    func status(workspace: Workspace, config: RemoteAIConfig) async -> SyncHealth {
        guard let executable = try? await ToolLocator.mutagenExecutable(runner: runner) else {
            return .missing
        }
        let name = sessionName(workspace: workspace, config: config)
        guard let result = try? await runner.run(executable: executable, arguments: ["sync", "list", name]) else {
            return .unavailable("Не удалось получить состояние Mutagen.")
        }
        guard result.exitCode == 0, result.stdout.contains("Name: \(name)") else {
            return .missing
        }
        return MutagenStatusParser.parse(result.stdout)
    }

    func endpoint(workspace: Workspace, config: RemoteAIConfig) -> String {
        let port = config.port == 22 ? "" : ":\(config.port)"
        return "\(config.user)@\(config.host)\(port):\(workspace.remotePath)"
    }

    private func routeSessionPrefix(workspace: Workspace) -> String {
        "rai-\(String(workspace.id.prefix(40)))-"
    }
}

enum MutagenSessionListParser {
    static func names(from output: String) -> [String] {
        output
            .split(separator: "\n")
            .compactMap { line -> String? in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.hasPrefix("Name:") else { return nil }
                let value = trimmed.dropFirst("Name:".count).trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
    }
}

struct MutagenStatusParser {
    static func parse(_ output: String) -> SyncHealth {
        let lower = output.lowercased()
        let conflictLines = lower.split(separator: "\n").filter { $0.contains("conflict") }
        let hasRealConflict = conflictLines.contains { line in
            !line.contains("conflicts: 0") &&
            !line.contains("0 conflicts") &&
            !line.contains("no conflicts")
        }
        if hasRealConflict {
            return .conflict("Mutagen обнаружил конфликт синхронизации.")
        }
        if lower.contains("paused") {
            return .paused
        }
        if lower.contains("watching for changes") {
            return .ready
        }
        let activeWords = ["scanning", "staging", "reconcil", "transition", "propagating"]
        if activeWords.contains(where: lower.contains) {
            return .syncing("Mutagen синхронизирует изменения.")
        }
        if lower.contains("unable to connect") || lower.contains("disconnected") {
            return .unavailable("Mutagen не может подключиться к удалённому рабочему пространству.")
        }
        return .ready
    }
}
