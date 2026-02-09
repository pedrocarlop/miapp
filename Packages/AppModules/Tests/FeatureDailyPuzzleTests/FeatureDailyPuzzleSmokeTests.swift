import XCTest
@testable import FeatureDailyPuzzle

final class FeatureDailyPuzzleSmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertTrue(FeatureDailyPuzzleUseCaseMarker.self is Any.Type)
    }
}
