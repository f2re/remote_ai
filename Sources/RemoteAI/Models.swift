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
        case .offline: "Remote AI: не в сети"
        case .connecting: "Remote AI: подключение"
        case .syncing: "Remote AI: синхронизация файлов"
        case .thinking: "Claude Code выполняет задачу"
        case .waiting: "Claude Code ожидает ввода"
        case .error(let message): "Ошибка Remote AI: \(message)"
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

    func primaryAction(hasConfiguredHost: Bool, hasWorkspace: Bool) -> MascotPrimaryAction {
        guard hasConfiguredHost else { return .openSettings }
        guard hasWorkspace else { return .chooseProject }

        switch self {
        case .offline, .error:
            return .startOrReconnect
        case .connecting, .syncing, .thinking, .waiting:
            return .openWarp
        }
    }
}

enum MascotPrimaryAction: Equatable, Sendable {
    case openSettings
    case chooseProject
    case startOrReconnect
    case openWarp
}

struct RemoteAIConfig: Codable, Equatable, Sendable {
    var host: String = ""
    var user: String = NSUserName()
    var port: Int = 22
    var sshKeyPath: String = ""
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
            throw RemoteAIError.invalidConfiguration("Укажите имя хоста, IPv4-адрес или SSH-псевдоним. Разрешены буквы, цифры, точка, подчёркивание и дефис.")
        }
        guard !user.isEmpty, user.wholeMatch(of: userPattern) != nil else {
            throw RemoteAIError.invalidConfiguration("Имя SSH-пользователя содержит недопустимые символы.")
        }
        guard (1...65535).contains(port) else {
            throw RemoteAIError.invalidConfiguration("SSH-порт должен быть в диапазоне от 1 до 65535.")
        }
        guard !remoteRoot.isEmpty, remoteRoot.wholeMatch(of: remotePattern) != nil, !remoteRoot.contains(":") else {
            throw RemoteAIError.invalidConfiguration("Корневая папка на сервере должна быть обычным путём без двоеточий и shell-синтаксиса.")
        }
        guard pollIntervalSeconds >= 1 else {
            throw RemoteAIError.invalidConfiguration("Интервал обновления состояния должен быть не меньше одной секунды.")
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

        var root = remoteRoot.trimmingCharacters(in: .whitespacesAndNewlines)
        while root.count > 1, root.hasSuffix("/") {
            root.removeLast()
        }
        let remotePath = root.isEmpty ? id : "\(root)/\(id)"

        return Workspace(
            id: id,
            name: URL(fileURLWithPath: standardized).lastPathComponent,
            localPath: standardized,
            remotePath: remotePath,
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
    var reportedState: MascotState?
}

enum RemoteAIError: LocalizedError, Equatable {
    case invalidConfiguration(String)
    case dependencyMissing(String)
    case connectionFailed(String)
    case commandFailed(String)
    case preflightFailed(String)
    case synchronizationConflict(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message),
             .dependencyMissing(let message),
             .connectionFailed(let message),
             .commandFailed(let message),
             .preflightFailed(let message),
             .synchronizationConflict(let message):
            message
        }
    }
}
