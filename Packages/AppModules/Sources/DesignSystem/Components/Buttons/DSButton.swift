import SwiftUI

public struct DSButton: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }

    private let title: String
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(TypographyTokens.bodyStrong)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, SpacingTokens.md)
                .padding(.vertical, SpacingTokens.sm)
                .frame(maxWidth: .infinity)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return ColorTokens.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ColorTokens.accentPrimary
        case .secondary:
            return ColorTokens.surfaceSecondary
        case .destructive:
            return ColorTokens.error
        }
    }
}
