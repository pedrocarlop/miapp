import SwiftUI

public extension View {
    func dsCardStyle() -> some View {
        padding(SpacingTokens.md)
            .background(
                RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                    .fill(ColorTokens.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                    .stroke(ColorTokens.borderDefault, lineWidth: 1)
            )
    }
}
