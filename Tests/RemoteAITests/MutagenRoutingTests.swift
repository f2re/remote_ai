import XCTest
@testable import RemoteAI

final class MutagenRoutingTests: XCTestCase {
    func testSessionNameIsStableForSameRoute() {
        var config = RemoteAIConfig()
        config.host = "buildbox.example"
        config.user = "dev"
        config.port = 22
        let workspace = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: ".remote-ai/workspaces")
        let controller = MutagenController()

        XCTAssertEqual(
            controller.sessionName(workspace: workspace, config: config),
            controller.sessionName(workspace: workspace, config: config)
        )
    }

    func testSessionNameChangesWhenRemoteRouteChanges() {
        var first = RemoteAIConfig()
        first.host = "buildbox.example"
        first.user = "dev"
        first.port = 22

        var second = first
        second.host = "other.example"

        var third = first
        third.port = 2222

        let workspace = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: ".remote-ai/workspaces")
        let controller = MutagenController()

        let firstName = controller.sessionName(workspace: workspace, config: first)
        XCTAssertNotEqual(firstName, controller.sessionName(workspace: workspace, config: second))
        XCTAssertNotEqual(firstName, controller.sessionName(workspace: workspace, config: third))
    }

    func testSessionNameChangesWhenRemoteRootChanges() {
        var config = RemoteAIConfig()
        config.host = "buildbox.example"
        config.user = "dev"

        let firstWorkspace = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: ".remote-ai/workspaces")
        let secondWorkspace = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: "/srv/remote-ai")
        let controller = MutagenController()

        XCTAssertNotEqual(
            controller.sessionName(workspace: firstWorkspace, config: config),
            controller.sessionName(workspace: secondWorkspace, config: config)
        )
    }

    func testSessionListParserFindsNames() {
        let output = """
        Identifier: abc
        Name: demo-old
        Alpha:
          URL: /tmp/demo
        Identifier: def
        Name: rai-demo-1234567890
        Beta:
          URL: user@host:path
        """

        XCTAssertEqual(
            MutagenSessionListParser.names(from: output),
            ["demo-old", "rai-demo-1234567890"]
        )
    }

    func testCustomPortEndpointUsesDocumentedMutagenSyntax() {
        var config = RemoteAIConfig()
        config.host = "buildbox.example"
        config.user = "dev"
        config.port = 2222
        let workspace = Workspace.make(localPath: "/Users/test/Projects/demo", remoteRoot: ".remote-ai/workspaces")

        XCTAssertEqual(
            MutagenController().endpoint(workspace: workspace, config: config),
            "dev@buildbox.example:2222:\(workspace.remotePath)"
        )
    }
}
