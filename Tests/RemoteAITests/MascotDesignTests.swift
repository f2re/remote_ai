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
}
