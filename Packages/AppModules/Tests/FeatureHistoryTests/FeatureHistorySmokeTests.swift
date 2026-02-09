import XCTest
@testable import FeatureHistory

final class FeatureHistorySmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertTrue(FeatureHistoryUseCaseMarker.self is Any.Type)
    }
}
