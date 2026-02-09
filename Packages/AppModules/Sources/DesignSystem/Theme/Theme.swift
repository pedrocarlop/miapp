import SwiftUI

public struct Theme {
    public let backgroundPrimary: Color
    public let surfacePrimary: Color
    public let surfaceSecondary: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let accentPrimary: Color

    public init(
        backgroundPrimary: Color,
        surfacePrimary: Color,
        surfaceSecondary: Color,
        textPrimary: Color,
        textSecondary: Color,
        accentPrimary: Color
    ) {
        self.backgroundPrimary = backgroundPrimary
        self.surfacePrimary = surfacePrimary
        self.surfaceSecondary = surfaceSecondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accentPrimary = accentPrimary
    }

    public static let `default` = Theme(
        backgroundPrimary: ColorTokens.backgroundPrimary,
        surfacePrimary: ColorTokens.surfacePrimary,
        surfaceSecondary: ColorTokens.surfaceSecondary,
        textPrimary: ColorTokens.textPrimary,
        textSecondary: ColorTokens.textSecondary,
        accentPrimary: ColorTokens.accentPrimary
    )
}
