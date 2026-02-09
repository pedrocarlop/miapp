import SwiftUI

public enum TypographyTokens {
    public static let titleLarge = Font.custom("InstrumentSerif-Regular", size: 72, relativeTo: .largeTitle)
    public static let titleMedium = Font.system(.title2, design: .default).weight(.semibold)
    public static let titleSmall = Font.system(.title3, design: .default).weight(.semibold)

    public static let body = Font.system(.body, design: .default)
    public static let bodyStrong = Font.system(.body, design: .default).weight(.semibold)
    public static let callout = Font.system(.callout, design: .default)
    public static let footnote = Font.system(.footnote, design: .default)
    public static let caption = Font.system(.caption, design: .default)

    public static let monoBody = Font.system(.body, design: .monospaced).weight(.semibold)
}
