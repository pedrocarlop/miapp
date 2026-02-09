import SwiftUI

public enum MotionTokens {
    public static let fastDuration: Double = 0.18
    public static let normalDuration: Double = 0.24
    public static let slowDuration: Double = 0.35

    public static let snappy = Animation.snappy(duration: normalDuration, extraBounce: 0.02)
    public static let smooth = Animation.easeInOut(duration: normalDuration)
    public static let celebrate = Animation.spring(response: slowDuration, dampingFraction: 0.78)
}
