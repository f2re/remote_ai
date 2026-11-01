import Foundation

enum SetupCheckKind: String, CaseIterable, Sendable {
    case configuration
    case project
    case sshKey
    case mutagen
    case ssh
    case tmux
    case claude

    var title: String {
        switch self {
        case .configuration: "Настройки"
        case .project: "Локальный проект"
        case .sshKey: "SSH-идентификация"
        case .mutagen: "Mutagen"
        case .ssh: "SSH-подключение"
        case .tmux: "Удалённый tmux"
        case .claude: "Удалённый Claude Code"
        }
    }
}

enum SetupCheckStatus: String, Sendable {
    case passed
    case warning
    case failed

    var label: String {
        switch self {
        case .passed: "Готово"
        case .warning: "Проверить"
        case .failed: "Ошибка"
        }
    }

    var systemImage: String {
        switch self {
        case .passed: "checkmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }
}

struct SetupCheck: Identifiable, Equatable, Sendable {
    let kind: SetupCheckKind
    let status: SetupCheckStatus
    let detail: String

    var id: SetupCheckKind { kind }
    var title: String { kind.title }
}

struct RemotePreflight: Equatable, Sendable {
    let ssh: Bool
    let tmux: Bool
    let tmuxVersion: String?
    let claude: Bool
    let claudeVersion: String?
}

enum RemotePreflightParser {
    static func parse(_ output: String) -> RemotePreflight {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        func value(_ key: String) -> String? {
            let prefix = "__RA_\(key)__="
            return lines.first { $0.hasPrefix(prefix) }.map { String($0.dropFirst(prefix.count)) }
        }

        return RemotePreflight(
            ssh: value("SSH") == "ok",
            tmux: value("TMUX") == "ok",
            tmuxVersion: value("TMUX_VERSION")?.nilIfEmpty,
            claude: value("CLAUDE") == "ok",
            claudeVersion: value("CLAUDE_VERSION")?.nilIfEmpty
        )
    }
}

struct SetupDiagnostics: Sendable {
    private let ssh = SSHController()

    func run(config: RemoteAIConfig, workspace: Workspace?) async -> [SetupCheck] {
        var checks: [SetupCheck] = []
        let configurationValid: Bool

        do {
            try config.validate()
            checks.append(.init(kind: .configuration, status: .passed, detail: "Параметры подключения корректны."))
            configurationValid = true
        } catch {
            checks.append(.init(kind: .configuration, status: .failed, detail: error.localizedDescription))
            configurationValid = false
        }

        if let workspace {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: workspace.localPath, isDirectory: &isDirectory)
            if exists, isDirectory.boolValue, FileManager.default.isReadableFile(atPath: workspace.localPath) {
                checks.append(.init(kind: .project, status: .passed, detail: workspace.localPath))
            } else {
                checks.append(.init(kind: .project, status: .failed, detail: "Выберите доступную для чтения локальную папку проекта."))
            }
        } else {
            checks.append(.init(kind: .project, status: .failed, detail: "Локальный проект не выбран."))
        }

        checks.append(sshIdentityCheck(config: config))

        do {
            let executable = try await ToolLocator.mutagenExecutable()
            checks.append(.init(kind: .mutagen, status: .passed, detail: executable))
        } catch {
            checks.append(.init(kind: .mutagen, status: .failed, detail: error.localizedDescription))
        }

        guard configurationValid else {
            checks += blockedRemoteChecks("Исправьте параметры подключения перед проверкой сервера.")
            return checks
        }

        do {
            let result = try await ssh.run(remoteCommand: Self.remoteProbeCommand, config: config)
            let probe = RemotePreflightParser.parse(result.stdout)
            checks.append(.init(
                kind: .ssh,
                status: probe.ssh ? .passed : .failed,
                detail: probe.ssh ? "Подключение к \(config.host) установлено." : "Сервер не вернул контрольную метку SSH Remote AI."
            ))
            checks.append(.init(
                kind: .tmux,
                status: probe.tmux ? .passed : .failed,
                detail: probe.tmux ? (probe.tmuxVersion ?? "tmux доступен.") : "Установите tmux на удалённом сервере."
            ))
            checks.append(.init(
                kind: .claude,
                status: probe.claude ? .passed : .failed,
                detail: probe.claude ? (probe.claudeVersion ?? "Claude Code доступен.") : "Установите Claude Code на удалённом сервере и добавьте его в PATH login shell."
            ))
        } catch {
            checks += [
                .init(kind: .ssh, status: .failed, detail: error.localizedDescription),
                .init(kind: .tmux, status: .failed, detail: "Сначала необходимо исправить SSH-подключение."),
                .init(kind: .claude, status: .failed, detail: "Сначала необходимо исправить SSH-подключение.")
            ]
        }

        return checks
    }

    private func sshIdentityCheck(config: RemoteAIConfig) -> SetupCheck {
        let raw = config.sshKeyPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            return .init(kind: .sshKey, status: .passed, detail: "Используются ~/.ssh/config, ssh-agent или стандартные ключи OpenSSH.")
        }

        let path = LocalPath.expandTilde(raw)
        guard FileManager.default.isReadableFile(atPath: path) else {
            return .init(kind: .sshKey, status: .failed, detail: "Файл ключа недоступен для чтения: \(path)")
        }

        let defaultNames = ["id_ed25519", "id_ecdsa", "id_rsa"]
        if defaultNames.contains(URL(fileURLWithPath: path).lastPathComponent) {
            return .init(kind: .sshKey, status: .passed, detail: path)
        }

        return .init(
            kind: .sshKey,
            status: .warning,
            detail: "Прямой SSH использует этот ключ. Для Mutagen также задайте IdentityFile для данного хоста в ~/.ssh/config, чтобы оба транспорта использовали один ключ."
        )
    }

    private func blockedRemoteChecks(_ message: String) -> [SetupCheck] {
        [
            .init(kind: .ssh, status: .failed, detail: message),
            .init(kind: .tmux, status: .failed, detail: message),
            .init(kind: .claude, status: .failed, detail: message)
        ]
    }

    private static let remoteProbeCommand = #"""
printf '__RA_SSH__=ok\n'
if command -v tmux >/dev/null 2>&1; then
  printf '__RA_TMUX__=ok\n'
  printf '__RA_TMUX_VERSION__='
  tmux -V 2>/dev/null | head -n 1
else
  printf '__RA_TMUX__=missing\n'
fi
if command -v claude >/dev/null 2>&1; then
  printf '__RA_CLAUDE__=ok\n'
  printf '__RA_CLAUDE_VERSION__='
  claude --version 2>/dev/null | head -n 1
else
  printf '__RA_CLAUDE__=missing\n'
fi
"""#
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
