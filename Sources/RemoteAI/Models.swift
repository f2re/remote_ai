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

struct WorkspaceFolder: Codable, Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var localPath: String
    var remoteSubpath: String

    init(localPath: String) {
        let standardized = URL(fileURLWithPath: localPath).standardizedFileURL.path
        let folderName = URL(fileURLWithPath: standardized).lastPathComponent
        let shortHash = String(StableHash.fnv1a64(standardized).prefix(6))
        self.id = "\(Identifier.sanitize(folderName, fallback: "dir"))-\(shortHash)"
        self.name = folderName.isEmpty ? "folder" : folderName
        self.localPath = standardized
        self.remoteSubpath = Identifier.sanitize(folderName, fallback: "dir")
    }

    init(id: String, name: String, localPath: String, remoteSubpath: String) {
        self.id = id
        self.name = name
        self.localPath = localPath
        self.remoteSubpath = remoteSubpath
    }
}

struct Workspace: Codable, Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var folders: [WorkspaceFolder]
    let remotePath: String
    let sessionName: String

    var localPath: String {
        folders.first?.localPath ?? ""
    }

    var localPaths: [String] {
        folders.map(\.localPath)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case folders
        case localPath
        case remotePath
        case sessionName
    }

    init(id: String, name: String, folders: [WorkspaceFolder], remotePath: String, sessionName: String) {
        self.id = id
        self.name = name
        self.folders = folders
        self.remotePath = remotePath
        self.sessionName = sessionName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.remotePath = try container.decode(String.self, forKey: .remotePath)
        self.sessionName = try container.decode(String.self, forKey: .sessionName)

        if let decodedFolders = try? container.decode([WorkspaceFolder].self, forKey: .folders), !decodedFolders.isEmpty {
            self.folders = decodedFolders
        } else if let singlePath = try? container.decode(String.self, forKey: .localPath), !singlePath.isEmpty {
            self.folders = [WorkspaceFolder(localPath: singlePath)]
        } else {
            self.folders = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(folders, forKey: .folders)
        try container.encode(localPath, forKey: .localPath)
        try container.encode(remotePath, forKey: .remotePath)
        try container.encode(sessionName, forKey: .sessionName)
    }

    func remotePath(for folder: WorkspaceFolder) -> String {
        if folders.count <= 1 {
            return remotePath
        }
        return "\(remotePath)/\(folder.remoteSubpath)"
    }

    static func make(name: String? = nil, localPaths: [String], remoteRoot: String) -> Workspace {
        let folders = localPaths.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.map { WorkspaceFolder(localPath: $0) }
        let primaryPath = folders.first?.localPath ?? ""
        let primaryName = folders.first?.name ?? "project"
        let chosenName = (name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? name! : primaryName

        let shortHash = String(StableHash.fnv1a64(primaryPath.isEmpty ? chosenName : primaryPath).prefix(8))
        let base = String(Identifier.sanitize(chosenName, fallback: "project").prefix(32))
        let id = "\(base)-\(shortHash)"

        var root = remoteRoot.trimmingCharacters(in: .whitespacesAndNewlines)
        while root.count > 1, root.hasSuffix("/") {
            root.removeLast()
        }
        let remotePath = root.isEmpty ? id : "\(root)/\(id)"

        return Workspace(
            id: id,
            name: chosenName,
            folders: folders,
            remotePath: remotePath,
            sessionName: "rai-\(id)"
        )
    }

    static func make(localPath: String, remoteRoot: String) -> Workspace {
        make(name: nil, localPaths: [localPath], remoteRoot: remoteRoot)
    }
}

struct WorkspaceCollection: Codable, Equatable, Sendable {
    var activeWorkspaceID: String?
    var workspaces: [Workspace]
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
