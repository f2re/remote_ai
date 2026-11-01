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
            return "SSH authentication failed. Check the user, SSH key/agent, and ~/.ssh/config for this host."
        }
        if lower.contains("could not resolve hostname") || lower.contains("name or service not known") {
            return "SSH host could not be resolved. Check the hostname or SSH alias."
        }
        if lower.contains("connection timed out") || lower.contains("operation timed out") {
            return "SSH connection timed out after 10 seconds. Check the host, port, VPN, firewall, or network route."
        }
        if lower.contains("connection refused") {
            return "SSH connection was refused. Check that sshd is running and the configured port is correct."
        }
        if lower.contains("host key verification failed") {
            return "SSH host-key verification failed. Resolve the host entry in ~/.ssh/known_hosts before reconnecting."
        }
        if trimmed.isEmpty {
            return "SSH command failed without diagnostic output."
        }
        return "SSH failed: \(trimmed)"
    }
}
