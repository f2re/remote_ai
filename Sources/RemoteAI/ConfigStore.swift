import Foundation

struct ConfigStore: Sendable {
    private let fileManager = FileManager.default

    var directoryURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("remote-ai", isDirectory: true)
    }

    var configURL: URL { directoryURL.appendingPathComponent("config.json") }
    var workspaceURL: URL { directoryURL.appendingPathComponent("workspace.json") }

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

    func loadWorkspace() throws -> Workspace? {
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
