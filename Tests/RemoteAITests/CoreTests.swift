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

    func testShellQuoteHandlesSingleQuote() {
        XCTAssertEqual(Shell.quote("a'b"), "'a'\"'\"'b'")
    }

    func testRemoteRelativePathUsesHome() {
        XCTAssertEqual(RemotePath.shellExpression(".remote-ai/workspaces/demo"), "\"$HOME\"/'.remote-ai/workspaces/demo'")
    }

    func testPaneParserDetectsThinkingNearTail() {
        let pane = "previous output\nWorking…\nesc to interrupt\n"
        XCTAssertEqual(PaneStatusParser.state(from: pane), .thinking)
    }

    func testPaneParserDefaultsToWaitingWhenIdle() {
        let pane = "Done. Tests pass.\n>\n"
        XCTAssertEqual(PaneStatusParser.state(from: pane), .waiting)
    }

    func testMutagenConflictWinsStatusPrecedence() {
        let output = "Name: demo\nStatus: Watching for changes\nConflicts: 1\n"
        XCTAssertEqual(MutagenStatusParser.parse(output), .conflict("Mutagen reports a synchronization conflict"))
    }

    func testMutagenReady() {
        let output = "Name: demo\nStatus: Watching for changes\n"
        XCTAssertEqual(MutagenStatusParser.parse(output), .ready)
    }
}
