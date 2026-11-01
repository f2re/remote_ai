import Foundation

struct SSHController: Sendable {
    private let runner = ProcessRunner()

    func run(remoteCommand: String, config: RemoteAIConfig) async throws -> ProcessResult {
        let result = try await runner.run(
            executable: "/usr/bin/ssh",
            arguments: arguments(config: config, interactive: false) + [Self.loginShellCommand(remoteCommand)]
        )
        guard result.exitCode == 0 else {
            throw RemoteAIError.connectionFailed(SSHFailureMessage.describe(result.combinedOutput))
        }
        return result
    }

    func interactiveShellCommand(remoteCommand: String, config: RemoteAIConfig) -> String {
        let argv = ["/usr/bin/ssh"] + arguments(config: config, interactive: true) + [Self.loginShellCommand(remoteCommand)]
        return argv.map(Shell.quote).joined(separator: " ")
    }

    static func loginShellCommand(_ command: String) -> String {
        "exec \"${SHELL:-/bin/sh}\" -lc \(Shell.quote(command))"
    }

    private func arguments(config: RemoteAIConfig, interactive: Bool) -> [String] {
        var args = [
            "-p", String(config.port),
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ConnectTimeout=10",
            "-o", "ConnectionAttempts=1",
            "-o", "ServerAliveInterval=15",
            "-o", "ServerAliveCountMax=3",
            "-o", "LogLevel=ERROR"
        ]
        if !interactive {
            args += ["-o", "BatchMode=yes"]
        }
        let rawKey = config.sshKeyPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !rawKey.isEmpty {
            args += ["-i", LocalPath.expandTilde(rawKey)]
        }
        if interactive {
            args.append("-t")
        }
        args.append("\(config.user)@\(config.host)")
        return args
    }
}

enum SSHFailureMessage {
    static func describe(_ output: String) -> String {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if lower.contains("permission denied") {
            return "Не удалось пройти SSH-аутентификацию. Проверьте пользователя, SSH-ключ или ssh-agent и настройки ~/.ssh/config для этого хоста."
        }
        if lower.contains("could not resolve hostname") || lower.contains("name or service not known") {
            return "Не удалось определить адрес SSH-хоста. Проверьте имя хоста или SSH-псевдоним."
        }
        if lower.contains("connection timed out") || lower.contains("operation timed out") {
            return "SSH-подключение не установлено за 10 секунд. Проверьте хост, порт, VPN, межсетевой экран и сетевой маршрут."
        }
        if lower.contains("connection refused") {
            return "SSH-соединение отклонено. Проверьте, что sshd запущен и указан правильный порт."
        }
        if lower.contains("host key verification failed") {
            return "Проверка SSH-ключа хоста не пройдена. Исправьте запись в ~/.ssh/known_hosts и повторите подключение."
        }
        if trimmed.isEmpty {
            return "Команда SSH завершилась ошибкой без диагностического сообщения."
        }
        return "Ошибка SSH. Диагностика удалённого инструмента: \(trimmed)"
    }
}
