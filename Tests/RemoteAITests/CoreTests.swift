import XCTest
@testable import RemoteAI

final class CoreTests: XCTestCase {
    func testWorkspaceIdentityIsDeterministic() {
        let first = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: ".remote-ai/workspaces")
        let second = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: ".remote-ai/workspaces")
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.remotePath, second.remotePath)
        XCTAssertTrue(first.sessionName.hasPrefix("rai-"))
    }

    func testAbsoluteRemoteRootIsPreserved() {
        let workspace = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: "/var/tmp/remote-ai/")
        XCTAssertTrue(workspace.remotePath.hasPrefix("/var/tmp/remote-ai/"))
    }

    func testShellQuoteHandlesSingleQuote() {
        XCTAssertEqual(Shell.quote("a'b"), "'a'\"'\"'b'")
    }

    func testRemoteRelativePathUsesHome() {
        XCTAssertEqual(RemotePath.shellExpression(".remote-ai/workspaces/demo"), "\"$HOME\"/'.remote-ai/workspaces/demo'")
    }

    func testPaneParserDetectsThinkingNearTail() {
        let pane = "предыдущий вывод\nРаботает…\nнажмите esc для остановки\n"
        XCTAssertEqual(PaneStatusParser.state(from: pane), .thinking)
    }

    func testPaneParserDefaultsToWaitingWhenIdle() {
        let pane = "Готово. Тесты пройдены.\n>\n"
        XCTAssertEqual(PaneStatusParser.state(from: pane), .waiting)
    }

    func testHookStateParserPrefersLifecycleSignal() {
        XCTAssertEqual(HookStateParser.state(fromMarkerLine: "__RA_STATE__=thinking|1793526000"), .thinking)
        XCTAssertEqual(HookStateParser.state(fromMarkerLine: "__RA_STATE__=waiting|1793526001"), .waiting)
        XCTAssertEqual(HookStateParser.state(fromMarkerLine: "__RA_STATE__=offline|1793526002"), .offline)
    }

    func testHookStateParserMapsFailure() {
        XCTAssertEqual(HookStateParser.state(fromMarkerLine: "__RA_STATE__=error|1793526000"), .error("Claude Code сообщил об ошибке выполнения задачи"))
    }

    func testMutagenConflictWinsStatusPrecedence() {
        let output = "Name: demo\nStatus: Watching for changes\nConflicts: 1\n"
        XCTAssertEqual(MutagenStatusParser.parse(output), .conflict("Mutagen обнаружил конфликт синхронизации."))
    }

    func testMutagenZeroConflictsIsReady() {
        let output = "Name: demo\nStatus: Watching for changes\nConflicts: 0\n"
        XCTAssertEqual(MutagenStatusParser.parse(output), .ready)
    }

    func testMutagenReady() {
        let output = "Name: demo\nStatus: Watching for changes\n"
        XCTAssertEqual(MutagenStatusParser.parse(output), .ready)
    }

    func testMutagenEndpointIncludesCustomPort() {
        var config = RemoteAIConfig()
        config.host = "buildbox.example"
        config.user = "dev"
        config.port = 2222
        let workspace = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: ".remote-ai/workspaces")
        XCTAssertTrue(MutagenController().endpoint(workspace: workspace, config: config).hasPrefix("dev@buildbox.example:2222:"))
    }

    func testConfigRejectsShellSyntaxInHost() {
        var config = RemoteAIConfig()
        config.host = "server;rm"
        XCTAssertThrowsError(try config.validate())
    }

    func testWarpConfigBuildsLocalReviewAndLiveClaudePanes() {
        var config = RemoteAIConfig()
        config.host = "buildbox.example"
        config.user = "dev"
        let workspace = Workspace.make(localPath: "/Users/test/My Project", remoteRoot: ".remote-ai/workspaces")
        let attach = "/usr/bin/ssh -t dev@buildbox.example 'tmux attach-session -t rai-demo'"

        let output = WarpTabConfigBuilder.content(workspace: workspace, config: config, attachCommand: attach)

        XCTAssertTrue(output.contains("split = \"horizontal\""))
        XCTAssertTrue(output.contains("children = [\"review\", \"claude\"]"))
        XCTAssertTrue(output.contains("directory = \"/Users/test/My Project\""))
        XCTAssertTrue(output.contains("Состояние Git"))
        XCTAssertTrue(output.contains("git status --short --branch"))
        XCTAssertTrue(output.contains("git diff --name-status"))
        XCTAssertTrue(output.contains("git ls-files --others --exclude-standard"))
        XCTAssertTrue(output.contains("is_focused = true"))
        XCTAssertTrue(output.contains("tmux attach-session"))
    }

    func testWarpConfigStemIsStableAndURLSafe() {
        let workspace = Workspace.make(localPath: "/Users/test/Projects/My Demo", remoteRoot: ".remote-ai/workspaces")
        let stem = WarpTabConfigBuilder.fileStem(for: workspace)
        XCTAssertTrue(stem.hasPrefix("remote_ai_"))
        XCTAssertFalse(stem.contains("-"))
        XCTAssertFalse(stem.contains(" "))
    }

    func testTOMLStringEscapesQuotesAndBackslashes() {
        XCTAssertEqual(TOML.string("a\\b\"c"), "\"a\\\\b\\\"c\"")
    }

    func testMultiFolderWorkspaceInitializationAndDecoding() throws {
        let ws = Workspace.make(
            name: "FullStack",
            localPaths: ["/Users/test/Projects/frontend", "/Users/test/Projects/backend"],
            remoteRoot: ".remote-ai/workspaces"
        )
        XCTAssertEqual(ws.name, "FullStack")
        XCTAssertEqual(ws.folders.count, 2)
        XCTAssertEqual(ws.localPath, "/Users/test/Projects/frontend")
        XCTAssertEqual(ws.localPaths, ["/Users/test/Projects/frontend", "/Users/test/Projects/backend"])
        XCTAssertTrue(ws.remotePath(for: ws.folders[1]).hasSuffix("/backend"))

        let encoded = try JSONEncoder().encode(ws)
        let decoded = try JSONDecoder().decode(Workspace.self, from: encoded)
        XCTAssertEqual(decoded.id, ws.id)
        XCTAssertEqual(decoded.folders.count, 2)
        XCTAssertEqual(decoded.folders[1].name, "backend")
    }

    func testLegacyWorkspaceSinglePathDecodingBackwardCompatibility() throws {
        let legacyJSON = """
        {
          "id": "myproject-12345678",
          "name": "myproject",
          "localPath": "/Users/test/LegacyProject",
          "remotePath": ".remote-ai/workspaces/myproject-12345678",
          "sessionName": "rai-myproject-12345678"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Workspace.self, from: legacyJSON)
        XCTAssertEqual(decoded.name, "myproject")
        XCTAssertEqual(decoded.folders.count, 1)
        XCTAssertEqual(decoded.localPath, "/Users/test/LegacyProject")
    }

    func testMutagenSessionNamesForMultiFolderWorkspace() {
        var config = RemoteAIConfig()
        config.host = "studio"
        config.user = "meteo"
        let ws = Workspace.make(
            name: "MonoRepo",
            localPaths: ["/Users/test/repo/app", "/Users/test/repo/api"],
            remoteRoot: ".remote-ai/workspaces"
        )
        let names = MutagenController().sessionNames(workspace: ws, config: config)
        XCTAssertEqual(names.count, 2)
        XCTAssertNotEqual(names[0], names[1])
        XCTAssertTrue(names[0].hasPrefix("rai-"))
        XCTAssertTrue(names[1].hasPrefix("rai-"))
    }
}
