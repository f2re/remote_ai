import Foundation

struct ProcessResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    var combinedOutput: String {
        [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

struct ProcessRunner: Sendable {
    func run(
        executable: String,
        arguments: [String],
        environment additions: [String: String] = [:]
    ) async throws -> ProcessResult {
        try await Task.detached(priority: .utility) {
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            if !additions.isEmpty {
                var environment = ProcessInfo.processInfo.environment
                for (key, value) in additions {
                    environment[key] = value
                }
                process.environment = environment
            }

            try process.run()
            process.waitUntilExit()

            let stdout = String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            let stderr = String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            return ProcessResult(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
        }.value
    }
}
