import SwiftUI

public struct DSText: View {
    public enum Style {
        case titleLarge
        case titleMedium
        case titleSmall
        case body
        case bodyStrong
        case footnote
        case caption
    }

    private let value: String
    private let style: Style
    private let color: Color

    public init(_ value: String, style: Style = .body, color: Color = ColorTokens.textPrimary) {
        self.value = value
        self.style = style
        self.color = color
    }

    public var body: some View {
        Text(value)
            .font(font)
            .foregroundStyle(color)
    }

    private var font: Font {
        switch style {
        case .titleLarge:
            return TypographyTokens.titleLarge
        case .titleMedium:
            return TypographyTokens.titleMedium
        case .titleSmall:
            return TypographyTokens.titleSmall
        case .body:
            return TypographyTokens.body
        case .bodyStrong:
            return TypographyTokens.bodyStrong
        case .footnote:
            return TypographyTokens.footnote
        case .caption:
            return TypographyTokens.caption
        }
    }
}
