import SwiftUI

public struct DSChip: View {
    private let text: String
    private let isSelected: Bool

    public init(text: String, isSelected: Bool = false) {
        self.text = text
        self.isSelected = isSelected
    }

    public var body: some View {
        Text(text)
            .font(TypographyTokens.caption)
            .foregroundStyle(ColorTokens.textPrimary)
            .padding(.horizontal, SpacingTokens.sm)
            .padding(.vertical, SpacingTokens.xs)
            .background(fillColor, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ColorTokens.chipBorder, lineWidth: 1)
            )
    }

    private var fillColor: Color {
        isSelected ? ColorTokens.accentPrimary.opacity(0.18) : ColorTokens.chipNeutralFill
    }
}
