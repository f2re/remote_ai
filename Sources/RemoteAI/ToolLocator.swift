import Foundation

enum ToolLocator {
    private static let mutagenCandidates = [
        "/opt/homebrew/bin/mutagen",
        "/usr/local/bin/mutagen",
        "/opt/local/bin/mutagen"
    ]

    static func mutagenExecutable(runner: ProcessRunner = ProcessRunner()) async throws -> String {
        for candidate in mutagenCandidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }

        if let result = try? await runner.run(executable: "/usr/bin/which", arguments: ["mutagen"]) {
            let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if result.exitCode == 0, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        throw RemoteAIError.dependencyMissing(
            "Mutagen is not installed or is not discoverable. Install it with: brew install mutagen-io/mutagen/mutagen"
        )
    }
}
