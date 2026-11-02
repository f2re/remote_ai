import XCTest
@testable import RemoteAI

@MainActor
final class MascotDesignTests: XCTestCase {
    func testEveryMascotStateMapsToCanonicalAsset() {
        XCTAssertEqual(MascotAsset(state: .offline), .offline)
        XCTAssertEqual(MascotAsset(state: .connecting), .connecting)
        XCTAssertEqual(MascotAsset(state: .syncing), .syncing)
        XCTAssertEqual(MascotAsset(state: .thinking), .thinking)
        XCTAssertEqual(MascotAsset(state: .waiting), .waiting)
        XCTAssertEqual(MascotAsset(state: .error("test")), .error)
    }

    func testEveryCanonicalMascotAssetIsBundledAndReadable() throws {
        XCTAssertEqual(MascotAsset.allCases.count, 6)
        for asset in MascotAsset.allCases {
            let url = try XCTUnwrap(asset.resourceURL, "Нет ресурса для \(asset.rawValue)")
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            let image = try XCTUnwrap(asset.cgImage, "PNG \(asset.rawValue) не декодируется через ImageIO")
            XCTAssertEqual(image.width, 256)
            XCTAssertEqual(image.height, 256)
        }
    }

    func testFirstRunPrimaryActionOpensSettingsBeforeProjectSelection() {
        XCTAssertEqual(MascotState.offline.primaryAction(hasConfiguredHost: false, hasWorkspace: false), .openSettings)
    }

    func testConfiguredHostWithoutWorkspaceChoosesProject() {
        XCTAssertEqual(MascotState.offline.primaryAction(hasConfiguredHost: true, hasWorkspace: false), .chooseProject)
    }

    func testOfflineConfiguredWorkspaceStartsAndActiveWorkspaceOpensWarp() {
        XCTAssertEqual(MascotState.offline.primaryAction(hasConfiguredHost: true, hasWorkspace: true), .startOrReconnect)
        XCTAssertEqual(MascotState.thinking.primaryAction(hasConfiguredHost: true, hasWorkspace: true), .openWarp)
        XCTAssertEqual(MascotState.error("failed").primaryAction(hasConfiguredHost: true, hasWorkspace: true), .startOrReconnect)
    }
}
