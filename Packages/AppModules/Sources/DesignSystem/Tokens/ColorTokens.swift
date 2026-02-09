import SwiftUI

public enum ColorTokens {
    public static let backgroundPrimary = Color(.systemGroupedBackground)
    public static let surfacePrimary = Color(.systemBackground)
    public static let surfaceSecondary = Color(.secondarySystemBackground)
    public static let surfaceTertiary = Color(.tertiarySystemBackground)

    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let accentPrimary = Color.accentColor
    public static let borderDefault = Color.primary.opacity(0.24)

    public static let success = Color(.systemGreen)
    public static let warning = Color(.systemOrange)
    public static let error = Color(.systemRed)

    public static let chipNeutralFill = surfaceTertiary
    public static let chipBorder = Color.primary.opacity(0.35)
    public static let chipFoundDecoration = Color.primary.opacity(0.8)

    public static let boardGridStroke = Color.secondary.opacity(0.18)
    public static let boardOuterStroke = Color.primary.opacity(0.45)
    public static let selectionFill = Color.accentColor.opacity(0.2)
    public static let feedbackCorrect = success
    public static let feedbackIncorrect = error
}
