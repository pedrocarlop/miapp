import XCTest
import Core
import CoreGraphics
@testable import FeatureDailyPuzzle

final class MetalFXConfigTests: XCTestCase {
    func testIsEnabledHonorsWaveToggle() {
        var config = FXConfig()
        config.enableWordSuccessWave = false

        XCTAssertFalse(config.isEnabled(for: .wordSuccessWave))
        XCTAssertTrue(config.isEnabled(for: .wordSuccessScanline))
    }

    func testIsEnabledHonorsScanlineToggle() {
        var config = FXConfig()
        config.enableWordSuccessScanline = false

        XCTAssertFalse(config.isEnabled(for: .wordSuccessScanline))
        XCTAssertTrue(config.isEnabled(for: .wordSuccessWave))
    }

    func testClipSpacePointUsesExpectedFormula() {
        let size = CGSize(width: 100, height: 80)

        let topLeft = MetalFXCoordinateMapper.clipSpacePoint(
            for: CGPoint(x: 0, y: 0),
            in: size
        )
        XCTAssertEqual(topLeft.x, -1, accuracy: 0.0001)
        XCTAssertEqual(topLeft.y, 1, accuracy: 0.0001)

        let center = MetalFXCoordinateMapper.clipSpacePoint(
            for: CGPoint(x: 50, y: 40),
            in: size
        )
        XCTAssertEqual(center.x, 0, accuracy: 0.0001)
        XCTAssertEqual(center.y, 0, accuracy: 0.0001)

        let bottomRight = MetalFXCoordinateMapper.clipSpacePoint(
            for: CGPoint(x: 100, y: 80),
            in: size
        )
        XCTAssertEqual(bottomRight.x, 1, accuracy: 0.0001)
        XCTAssertEqual(bottomRight.y, -1, accuracy: 0.0001)
    }

    func testPathPointsAlignWithCellCenters() {
        let bounds = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
        let points = MetalFXGridGeometry.pathPoints(
            for: [GridPosition(row: 1, col: 2), GridPosition(row: 3, col: 0)],
            in: bounds,
            rows: 4,
            cols: 4
        )

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].x, 125, accuracy: 0.0001)
        XCTAssertEqual(points[0].y, 75, accuracy: 0.0001)
        XCTAssertEqual(points[1].x, 25, accuracy: 0.0001)
        XCTAssertEqual(points[1].y, 175, accuracy: 0.0001)
    }
}
