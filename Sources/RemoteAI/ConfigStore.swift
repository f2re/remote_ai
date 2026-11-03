import Foundation

struct ConfigStore: Sendable {
    private var fileManager: FileManager { .default }

    var directoryURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("remote-ai", isDirectory: true)
    }

    var configURL: URL { directoryURL.appendingPathComponent("config.json") }
    var workspaceURL: URL { directoryURL.appendingPathComponent("workspace.json") }
    var workspacesURL: URL { directoryURL.appendingPathComponent("workspaces.json") }

    func loadConfig() throws -> RemoteAIConfig {
        guard fileManager.fileExists(atPath: configURL.path) else { return RemoteAIConfig() }
        return try JSONDecoder().decode(RemoteAIConfig.self, from: Data(contentsOf: configURL))
    }

    func saveConfig(_ config: RemoteAIConfig) throws {
        try ensureDirectory()
        let data = try JSONEncoder.pretty.encode(config)
        try data.write(to: configURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configURL.path)
    }

    func loadWorkspaces() throws -> WorkspaceCollection {
        if fileManager.fileExists(atPath: workspacesURL.path) {
            return try JSONDecoder().decode(WorkspaceCollection.self, from: Data(contentsOf: workspacesURL))
        }

        // Migrate from single workspace.json if present
        if fileManager.fileExists(atPath: workspaceURL.path),
           let legacy = try? JSONDecoder().decode(Workspace.self, from: Data(contentsOf: workspaceURL)) {
            let collection = WorkspaceCollection(activeWorkspaceID: legacy.id, workspaces: [legacy])
            try? saveWorkspaces(collection)
            return collection
        }

        return WorkspaceCollection(activeWorkspaceID: nil, workspaces: [])
    }

    func saveWorkspaces(_ collection: WorkspaceCollection) throws {
        try ensureDirectory()
        let data = try JSONEncoder.pretty.encode(collection)
        try data.write(to: workspacesURL, options: .atomic)

        // Also keep workspace.json updated with active workspace for backward compatibility
        if let active = collection.workspaces.first(where: { $0.id == collection.activeWorkspaceID }) ?? collection.workspaces.first {
            try? saveWorkspace(active)
        }
    }

    func loadWorkspace() throws -> Workspace? {
        if let collection = try? loadWorkspaces() {
            if let active = collection.workspaces.first(where: { $0.id == collection.activeWorkspaceID }) {
                return active
            }
            if let first = collection.workspaces.first {
                return first
            }
        }
        guard fileManager.fileExists(atPath: workspaceURL.path) else { return nil }
        return try JSONDecoder().decode(Workspace.self, from: Data(contentsOf: workspaceURL))
    }

    func saveWorkspace(_ workspace: Workspace) throws {
        try ensureDirectory()
        let data = try JSONEncoder.pretty.encode(workspace)
        try data.write(to: workspaceURL, options: .atomic)
    }

    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
