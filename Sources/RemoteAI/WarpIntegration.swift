import AppKit
import Foundation

@MainActor
struct WarpIntegration {
    private let fileManager = FileManager.default

    func open(workspace: Workspace, config: RemoteAIConfig, attachCommand: String) throws {
        let directory = LocalPath.expandTilde("~/.warp/tab_configs")
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)

        let stem = WarpTabConfigBuilder.fileStem(for: workspace)
        let path = URL(fileURLWithPath: directory, isDirectory: true)
            .appendingPathComponent("\(stem).toml")
        let content = WarpTabConfigBuilder.content(
            workspace: workspace,
            config: config,
            attachCommand: attachCommand
        )
        try content.write(to: path, atomically: true, encoding: .utf8)

        guard let deepLink = URL(string: "warp://tab_config/\(stem)") else {
            throw RemoteAIError.commandFailed("Не удалось создать deep link для Warp.")
        }
        guard NSWorkspace.shared.open(deepLink) else {
            throw RemoteAIError.dependencyMissing("Warp не установлен или не зарегистрировал схему URL warp://.")
        }
    }
}

enum WarpTabConfigBuilder {
    static func fileStem(for workspace: Workspace) -> String {
        let normalized = workspace.id.lowercased().map { character -> Character in
            character.isLetter || character.isNumber ? character : "_"
        }
        return "remote_ai_\(String(normalized))"
    }

    static func content(workspace: Workspace, config: RemoteAIConfig, attachCommand: String) -> String {
        let reviewCommands = [
            "clear",
            "printf '\\033[1mRemote AI · локальный обзор\\033[0m\\nПроект: %s\\nСервер: %s@%s:%s\\n\\n' \(Shell.quote(workspace.name)) \(Shell.quote(config.user)) \(Shell.quote(config.host)) \(Shell.quote(workspace.remotePath))",
            "printf '\\033[1mСостояние Git\\033[0m\\n'; git status --short --branch || true",
            "printf '\\n\\033[1mИзменённые отслеживаемые файлы\\033[0m\\n'; git diff --name-status || true",
            "printf '\\n\\033[1mНеотслеживаемые файлы\\033[0m\\n'; git ls-files --others --exclude-standard || true",
            "printf '\\n\\033[1mСводка изменений\\033[0m\\n'; git diff --stat || true",
            "printf '\\n\\033[2mНажмите путь к файлу в Warp, чтобы открыть его в редакторе. Справа находится текущая удалённая tmux-сессия Claude Code.\\033[0m\\n'"
        ]

        let commandArray = reviewCommands
            .map(TOML.string)
            .joined(separator: ", ")

        return """
        name = \(TOML.string("Remote AI · \(workspace.name)"))
        title = \(TOML.string("Remote AI · \(workspace.name)"))
        color = "cyan"

        [[panes]]
        id = "root"
        split = "horizontal"
        children = ["review", "claude"]

        [[panes]]
        id = "review"
        type = "terminal"
        directory = \(TOML.string(workspace.localPath))
        commands = [\(commandArray)]

        [[panes]]
        id = "claude"
        type = "terminal"
        directory = \(TOML.string(workspace.localPath))
        commands = [\(TOML.string(attachCommand))]
        is_focused = true
        """
    }
}

enum TOML {
    static func string(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
        escaped = escaped.replacingOccurrences(of: "\r", with: "\\r")
        escaped = escaped.replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }
}
