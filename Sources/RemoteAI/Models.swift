import Foundation

enum MascotState: Equatable, Sendable {
    case offline
    case connecting
    case syncing
    case thinking
    case waiting
    case error(String)

    var accessibilityLabel: String {
        switch self {
        case .offline: "Remote AI offline"
        case .connecting: "Remote AI connecting"
        case .syncing: "Remote AI synchronizing files"
        case .thinking: "Claude Code is working"
        case .waiting: "Claude Code is waiting for input"
        case .error(let message): "Remote AI error: \(message)"
        }
    }

    var systemImage: String {
        switch self {
        case .offline: "moon.zzz"
        case .connecting: "network"
        case .syncing: "arrow.triangle.2.circlepath"
        case .thinking: "sparkles"
        case .waiting: "checkmark.circle"
        case .error: "exclamationmark.triangle"
        }
    }
}

struct RemoteAIConfig: Codable, Equatable, Sendable {
    var host: String = ""
    var user: String = NSUserName()
    var port: Int = 22
    var sshKeyPath: String = "~/.ssh/id_ed25519"
    var remoteRoot: String = ".remote-ai/workspaces"
    var pollIntervalSeconds: Double = 3
    var notifyWhenWaiting: Bool = true

    static let defaultIgnores = [
        ".git",
        ".build",
        "DerivedData",
        "node_modules",
        "venv",
        ".venv",
        "__pycache__",
        "target",
        "build",
        "dist"
    ]

    func validate() throws {
        let hostPattern = /^[A-Za-z0-9._-]+$/
        let userPattern = /^[A-Za-z0-9._-]+$/
        let remotePattern = /^[A-Za-z0-9._~\/-]+$/

        guard !host.isEmpty, host.wholeMatch(of: hostPattern) != nil else {
            throw RemoteAIError.invalidConfiguration("Host must be a hostname, IPv4 address, or SSH alias using letters, digits, dot, underscore, or hyphen.")
        }
        guard !user.isEmpty, user.wholeMatch(of: userPattern) != nil else {
            throw RemoteAIError.invalidConfiguration("SSH user contains unsupported characters.")
        }
        guard (1...65535).contains(port) else {
            throw RemoteAIError.invalidConfiguration("SSH port must be between 1 and 65535.")
        }
        guard !remoteRoot.isEmpty, remoteRoot.wholeMatch(of: remotePattern) != nil, !remoteRoot.contains(":") else {
            throw RemoteAIError.invalidConfiguration("Remote root must be a simple path without colons or shell syntax.")
        }
        guard pollIntervalSeconds >= 1 else {
            throw RemoteAIError.invalidConfiguration("Polling interval must be at least one second.")
        }
    }
}

struct Workspace: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let localPath: String
    let remotePath: String
    let sessionName: String

    static func make(localPath: String, remoteRoot: String) -> Workspace {
        let standardized = URL(fileURLWithPath: localPath).standardizedFileURL.path
        let basename = Identifier.sanitize(URL(fileURLWithPath: standardized).lastPathComponent, fallback: "project")
        let hash = StableHash.fnv1a64(standardized)
        let shortHash = String(hash.prefix(8))
        let base = String(basename.prefix(32))
        let id = "\(base)-\(shortHash)"
        let root = remoteRoot.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return Workspace(
            id: id,
            name: URL(fileURLWithPath: standardized).lastPathComponent,
            localPath: standardized,
            remotePath: root.isEmpty ? id : "\(root)/\(id)",
            sessionName: "rai-\(id)"
        )
    }
}

enum SyncHealth: Equatable, Sendable {
    case missing
    case ready
    case syncing(String)
    case paused
    case conflict(String)
    case unavailable(String)
}

struct RuntimeSnapshot: Equatable, Sendable {
    var sessionExists: Bool
    var pane: String
}

enum RemoteAIError: LocalizedError, Equatable {
    case invalidConfiguration(String)
    case dependencyMissing(String)
    case commandFailed(String)
    case synchronizationConflict(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message),
             .dependencyMissing(let message),
             .commandFailed(let message),
             .synchronizationConflict(let message):
            message
        }
    }
}
