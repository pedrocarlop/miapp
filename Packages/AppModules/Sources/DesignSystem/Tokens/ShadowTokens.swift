import SwiftUI

public struct DSShadowToken {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

public enum ShadowTokens {
    public static let cardAmbient = DSShadowToken(
        color: Color.black.opacity(0.08),
        radius: 6,
        x: 0,
        y: 1
    )
    public static let cardDrop = DSShadowToken(
        color: Color.black.opacity(0.14),
        radius: 14,
        x: 0,
        y: 8
    )
}
