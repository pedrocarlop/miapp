import SwiftUI
import DesignSystem

public struct HistoryNavCounterView: View {
    public let value: Int
    public let systemImage: String
    public let iconGradient: LinearGradient
    public let accessibilityLabel: String
    public let accessibilityHint: String
    public let action: () -> Void

    public init(
        value: Int,
        systemImage: String,
        iconGradient: LinearGradient,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) {
        self.value = value
        self.systemImage = systemImage
        self.iconGradient = iconGradient
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingTokens.xxs) {
                Image(systemName: systemImage)
                    .font(TypographyTokens.caption.weight(.semibold))
                    .foregroundStyle(iconGradient)
                Text("\(value)")
                    .font(TypographyTokens.caption.weight(.semibold))
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}
