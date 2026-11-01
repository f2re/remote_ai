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
            let fileManager = FileManager.default
            let id = UUID().uuidString
            let stdoutURL = fileManager.temporaryDirectory.appendingPathComponent("remote-ai-\(id).out")
            let stderrURL = fileManager.temporaryDirectory.appendingPathComponent("remote-ai-\(id).err")
            fileManager.createFile(atPath: stdoutURL.path, contents: nil)
            fileManager.createFile(atPath: stderrURL.path, contents: nil)

            defer {
                try? fileManager.removeItem(at: stdoutURL)
                try? fileManager.removeItem(at: stderrURL)
            }

            let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
            let stderrHandle = try FileHandle(forWritingTo: stderrURL)
            defer {
                try? stdoutHandle.close()
                try? stderrHandle.close()
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutHandle
            process.standardError = stderrHandle

            if !additions.isEmpty {
                var environment = ProcessInfo.processInfo.environment
                for (key, value) in additions {
                    environment[key] = value
                }
                process.environment = environment
            }

            try process.run()
            process.waitUntilExit()
            try? stdoutHandle.synchronize()
            try? stderrHandle.synchronize()

            let stdout = (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? ""
            let stderr = (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? ""
            return ProcessResult(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
        }.value
    }
}
