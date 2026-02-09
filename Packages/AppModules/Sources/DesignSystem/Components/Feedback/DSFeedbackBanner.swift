import SwiftUI

public struct DSFeedbackBanner: View {
    public enum Kind {
        case success
        case warning
        case error
    }

    private let title: String
    private let message: String?
    private let kind: Kind

    public init(title: String, message: String? = nil, kind: Kind) {
        self.title = title
        self.message = message
        self.kind = kind
    }

    public var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            Image(systemName: icon)
                .font(TypographyTokens.bodyStrong)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                Text(title)
                    .font(TypographyTokens.bodyStrong)
                if let message {
                    Text(message)
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(SpacingTokens.sm)
        .background(ColorTokens.surfaceSecondary, in: RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RadiusTokens.md, style: .continuous)
                .stroke(color.opacity(0.35), lineWidth: 1)
        )
    }

    private var color: Color {
        switch kind {
        case .success: return ColorTokens.success
        case .warning: return ColorTokens.warning
        case .error: return ColorTokens.error
        }
    }

    private var icon: String {
        switch kind {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}
