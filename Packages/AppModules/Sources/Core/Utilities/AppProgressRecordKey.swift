import Foundation

public enum AppProgressRecordKey {
    public static func make(dayOffset: Int, gridSize: Int) -> String {
        "\(dayOffset)-\(gridSize)"
    }
}
