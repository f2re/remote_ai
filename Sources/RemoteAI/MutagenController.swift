import Foundation

struct MutagenController: Sendable {
    private let runner = ProcessRunner()

    func sessionName(workspace: Workspace, config: RemoteAIConfig) -> String {
        let route = "\(config.user)@\(config.host):\(config.port)|\(workspace.remotePath)"
        let routeHash = String(StableHash.fnv1a64(route).prefix(10))
        let workspacePart = String(workspace.id.prefix(40))
        return "rai-\(workspacePart)-\(routeHash)"
    }

    func sessionNames(workspace: Workspace, config: RemoteAIConfig) -> [String] {
        if workspace.folders.count <= 1 {
            return [sessionName(workspace: workspace, config: config)]
        }
        return workspace.folders.indices.map { idx in
            let folder = workspace.folders[idx]
            let remoteFolder = workspace.remotePath(for: folder)
            let route = "\(config.user)@\(config.host):\(config.port)|\(remoteFolder)"
            let routeHash = String(StableHash.fnv1a64(route).prefix(10))
            let folderPart = String(folder.remoteSubpath.prefix(12))
            let workspacePart = String(workspace.id.prefix(28))
            return "rai-\(workspacePart)-\(folderPart)-\(routeHash)"
        }
    }

    func ensureSession(workspace: Workspace, config: RemoteAIConfig) async throws {
        let executable = try await ToolLocator.mutagenExecutable(runner: runner)
        _ = try? await runner.run(executable: executable, arguments: ["daemon", "start"])

        guard !workspace.folders.isEmpty else { return }

        let foldersToSync: [(folder: WorkspaceFolder?, sessionName: String, localPath: String, remoteEndpoint: String)]
        if workspace.folders.count <= 1 {
            let single = workspace.folders.first
            let name = sessionName(workspace: workspace, config: config)
            let path = single?.localPath ?? workspace.localPath
            foldersToSync = [(single, name, path, endpoint(workspace: workspace, config: config))]
        } else {
            let names = sessionNames(workspace: workspace, config: config)
            foldersToSync = workspace.folders.indices.map { idx in
                let folder = workspace.folders[idx]
                let name = names[idx]
                return (folder, name, folder.localPath, endpoint(workspace: workspace, folder: folder, config: config))
            }
        }

        let listing = try await runner.run(executable: executable, arguments: ["sync", "list"])
        guard listing.exitCode == 0 else {
            throw RemoteAIError.commandFailed(listing.combinedOutput)
        }

        let existingNames = Set(MutagenSessionListParser.names(from: listing.stdout))
        for item in foldersToSync {
            if existingNames.contains(item.sessionName) {
                let resumed = try await runner.run(executable: executable, arguments: ["sync", "resume", item.sessionName])
                guard resumed.exitCode == 0 else {
                    throw RemoteAIError.commandFailed(resumed.combinedOutput)
                }
                continue
            }

            var arguments = [
                "sync", "create",
                "--name=\(item.sessionName)",
                "--sync-mode=two-way-safe"
            ]
            for ignored in RemoteAIConfig.defaultIgnores {
                arguments.append("--ignore=\(ignored)")
            }
            arguments += [item.localPath, item.remoteEndpoint]

            let created = try await runner.run(executable: executable, arguments: arguments)
            guard created.exitCode == 0 else {
                throw RemoteAIError.commandFailed(created.combinedOutput)
            }
        }
    }

    func flush(workspace: Workspace, config: RemoteAIConfig) async throws {
        let executable = try await ToolLocator.mutagenExecutable(runner: runner)
        let names = sessionNames(workspace: workspace, config: config)
        for name in names {
            let result = try await runner.run(
                executable: executable,
                arguments: ["sync", "flush", name]
            )
            guard result.exitCode == 0 else {
                throw RemoteAIError.commandFailed(result.combinedOutput)
            }
        }
    }

    func pause(workspace: Workspace, config: RemoteAIConfig) async {
        guard let executable = try? await ToolLocator.mutagenExecutable(runner: runner) else { return }
        let names = sessionNames(workspace: workspace, config: config)
        for name in names {
            _ = try? await runner.run(
                executable: executable,
                arguments: ["sync", "pause", name]
            )
        }
    }

    func status(workspace: Workspace, config: RemoteAIConfig) async -> SyncHealth {
        guard let executable = try? await ToolLocator.mutagenExecutable(runner: runner) else {
            return .missing
        }
        let names = sessionNames(workspace: workspace, config: config)
        var anySyncing: String?
        var anyPaused = false

        for name in names {
            guard let result = try? await runner.run(executable: executable, arguments: ["sync", "list", name]) else {
                return .unavailable("Не удалось получить состояние Mutagen.")
            }
            guard result.exitCode == 0, result.stdout.contains("Name: \(name)") else {
                return .missing
            }
            let health = MutagenStatusParser.parse(result.stdout)
            switch health {
            case .conflict(let message):
                return .conflict(message)
            case .syncing(let message):
                anySyncing = message
            case .paused:
                anyPaused = true
            case .unavailable(let message):
                return .unavailable(message)
            case .missing:
                return .missing
            case .ready:
                break
            }
        }

        if let anySyncing {
            return .syncing(anySyncing)
        }
        if anyPaused {
            return .paused
        }
        return .ready
    }

    func endpoint(workspace: Workspace, folder: WorkspaceFolder? = nil, config: RemoteAIConfig) -> String {
        let port = config.port == 22 ? "" : ":\(config.port)"
        let remotePath = folder != nil ? workspace.remotePath(for: folder!) : workspace.remotePath
        return "\(config.user)@\(config.host)\(port):\(remotePath)"
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
