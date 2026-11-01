import XCTest
@testable import RemoteAI

final class DiagnosticsTests: XCTestCase {
    func testRemotePreflightParserReadsAllMarkers() {
        let output = """
        __RA_SSH__=ok
        __RA_TMUX__=ok
        __RA_TMUX_VERSION__=tmux 3.5a
        __RA_CLAUDE__=ok
        __RA_CLAUDE_VERSION__=2.1.3 (Claude Code)
        """

        XCTAssertEqual(
            RemotePreflightParser.parse(output),
            RemotePreflight(
                ssh: true,
                tmux: true,
                tmuxVersion: "tmux 3.5a",
                claude: true,
                claudeVersion: "2.1.3 (Claude Code)"
            )
        )
    }

    func testRemotePreflightParserReportsMissingDependencies() {
        let output = "__RA_SSH__=ok\n__RA_TMUX__=missing\n__RA_CLAUDE__=missing\n"
        let result = RemotePreflightParser.parse(output)
        XCTAssertTrue(result.ssh)
        XCTAssertFalse(result.tmux)
        XCTAssertFalse(result.claude)
    }

    func testSSHFailureMessagesAreActionable() {
        XCTAssertEqual(
            SSHFailureMessage.describe("ssh: connect to host box port 22: Operation timed out"),
            "SSH connection timed out after 10 seconds. Check the host, port, VPN, firewall, or network route."
        )
        XCTAssertEqual(
            SSHFailureMessage.describe("dev@box: Permission denied (publickey)."),
            "SSH authentication failed. Check the user, SSH key/agent, and ~/.ssh/config for this host."
        )
        XCTAssertEqual(
            SSHFailureMessage.describe("ssh: Could not resolve hostname box: nodename nor servname provided"),
            "SSH host could not be resolved. Check the hostname or SSH alias."
        )
    }

    func testSSHCommandsUseLoginShellAndQuotePayload() {
        let wrapped = SSHController.loginShellCommand("printf '%s' a'b")
        XCTAssertTrue(wrapped.contains("${SHELL:-/bin/sh}"))
        XCTAssertTrue(wrapped.contains("-lc"))
        XCTAssertTrue(wrapped.contains("'\"'\"'"))
    }

    func testDefaultConfigurationUsesOpenSSHDiscovery() {
        XCTAssertEqual(RemoteAIConfig().sshKeyPath, "")
    }
}
