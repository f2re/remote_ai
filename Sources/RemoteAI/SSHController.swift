import Foundation

struct SSHController: Sendable {
    private let runner = ProcessRunner()

    func run(remoteCommand: String, config: RemoteAIConfig) async throws -> ProcessResult {
        let result = try await runner.run(
            executable: "/usr/bin/ssh",
            arguments: arguments(config: config, interactive: false) + [remoteCommand]
        )
        guard result.exitCode == 0 else {
            throw RemoteAIError.commandFailed(result.combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return result
    }

    func interactiveShellCommand(remoteCommand: String, config: RemoteAIConfig) -> String {
        let argv = ["/usr/bin/ssh"] + arguments(config: config, interactive: true) + [remoteCommand]
        return argv.map(Shell.quote).joined(separator: " ")
    }

    private func arguments(config: RemoteAIConfig, interactive: Bool) -> [String] {
        var args = [
            "-p", String(config.port),
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ServerAliveInterval=15",
            "-o", "ServerAliveCountMax=3"
        ]
        if !interactive {
            args += ["-o", "BatchMode=yes"]
        }
        let key = LocalPath.expandTilde(config.sshKeyPath)
        if !config.sshKeyPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args += ["-i", key]
        }
        if interactive {
            args.append("-t")
        }
        args.append("\(config.user)@\(config.host)")
        return args
    }
}
