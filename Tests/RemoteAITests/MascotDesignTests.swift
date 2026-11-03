import XCTest
@testable import RemoteAI

final class MascotDesignTests: XCTestCase {
    func testPixelCloudGridIsStable() {
        XCTAssertEqual(PixelCloudArt.rowCount, 10)
        XCTAssertEqual(PixelCloudArt.columns, 16)
        XCTAssertTrue(PixelCloudArt.rows.allSatisfy { $0.count == PixelCloudArt.columns })
        XCTAssertGreaterThan(PixelCloudArt.filledPixelCount, 90)
    }

    func testPixelCloudHasEmptyCornersAndFilledCenter() {
        XCTAssertFalse(PixelCloudArt.isFilled(x: 0, y: 0))
        XCTAssertFalse(PixelCloudArt.isFilled(x: 15, y: 0))
        XCTAssertTrue(PixelCloudArt.isFilled(x: 7, y: 4))
        XCTAssertTrue(PixelCloudArt.isFilled(x: 8, y: 5))
    }

    func testPixelCloudOutOfBoundsIsEmpty() {
        XCTAssertFalse(PixelCloudArt.isFilled(x: -1, y: 0))
        XCTAssertFalse(PixelCloudArt.isFilled(x: 16, y: 0))
        XCTAssertFalse(PixelCloudArt.isFilled(x: 0, y: 10))
    }

    func testFirstRunPrimaryActionOpensSettingsBeforeProjectSelection() {
        XCTAssertEqual(
            MascotState.offline.primaryAction(hasConfiguredHost: false, hasWorkspace: false),
            .openSettings
        )
    }

    func testConfiguredHostWithoutWorkspaceChoosesProject() {
        XCTAssertEqual(
            MascotState.offline.primaryAction(hasConfiguredHost: true, hasWorkspace: false),
            .chooseProject
        )
    }

    func testOfflineConfiguredWorkspaceStartsAndActiveWorkspaceOpensWarp() {
        XCTAssertEqual(
            MascotState.offline.primaryAction(hasConfiguredHost: true, hasWorkspace: true),
            .startOrReconnect
        )
        XCTAssertEqual(
            MascotState.thinking.primaryAction(hasConfiguredHost: true, hasWorkspace: true),
            .openWarp
        )
        XCTAssertEqual(
            MascotState.error("failed").primaryAction(hasConfiguredHost: true, hasWorkspace: true),
            .startOrReconnect
        )
    }

    @MainActor
    func testMascotWindowControllerToggleAndVisibility() {
        let model = AppModel()
        let controller = MascotWindowController(model: model)
        XCTAssertFalse(controller.isVisible)
        controller.show()
        XCTAssertTrue(controller.isVisible)
        controller.hide()
        XCTAssertFalse(controller.isVisible)
        controller.toggle()
        XCTAssertTrue(controller.isVisible)
        controller.hide()
    }

    @MainActor
    func testStatusBarControllerInitializes() {
        let model = AppModel()
        let controller = StatusBarController(model: model, mascotWindowController: nil)
        XCTAssertNotNil(controller)
    }

    func testPolishedMascotAssetsAllStatesLoad() {
        let states: [MascotState] = [.offline, .connecting, .syncing, .thinking, .waiting, .error("err")]
        for s in states {
            let img = PolishedMascotAssets.image(for: s)
            XCTAssertGreaterThan(img.size.width, 0)
            XCTAssertGreaterThan(img.size.height, 0)
        }
    }
}
