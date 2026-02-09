import XCTest
@testable import FeatureSettings

final class FeatureSettingsSmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertTrue(FeatureSettingsUseCaseMarker.self is Any.Type)
    }
}
