import SwiftUI
import Core
import DesignSystem

public struct DailyPuzzleWordsView: View {
    public let words: [String]
    public let foundWords: Set<String>
    public let displayMode: WordHintMode

    private let topFadeHeight: CGFloat = 14

    public init(words: [String], foundWords: Set<String>, displayMode: WordHintMode) {
        self.words = words
        self.foundWords = foundWords
        self.displayMode = displayMode
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Group {
                if displayMode == .definition {
                    LazyVStack(spacing: SpacingTokens.xs) {
                        ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                            let displayText = WordHintsService.displayText(for: word, mode: displayMode)
                            WordChip(
                                word: displayText,
                                styleSeed: index,
                                isFound: foundWords.contains(word.uppercased()),
                                allowMultiline: true,
                                expandsHorizontally: true
                            )
                        }
                    }
                    .padding(.trailing, SpacingTokens.xxs)
                } else {
                    WrappingFlowLayout(horizontalSpacing: SpacingTokens.xs, verticalSpacing: SpacingTokens.xs) {
                        ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                            let displayText = WordHintsService.displayText(for: word, mode: displayMode)
                            WordChip(
                                word: displayText,
                                styleSeed: index,
                                isFound: foundWords.contains(word.uppercased()),
                                allowMultiline: false,
                                expandsHorizontally: false
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, SpacingTokens.xxs)
                }
            }
            .padding(.top, SpacingTokens.xs)
            .padding(.bottom, SpacingTokens.sm)
        }
        .overlay(alignment: .top) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: ColorTokens.backgroundPrimary, location: 0.0),
                    .init(color: ColorTokens.backgroundPrimary.opacity(0.62), location: 0.48),
                    .init(color: ColorTokens.backgroundPrimary.opacity(0.0), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: topFadeHeight)
            .allowsHitTesting(false)
        }
    }
}

private struct WordChip: View {
    let word: String
    let styleSeed: Int
    let isFound: Bool
    let allowMultiline: Bool
    let expandsHorizontally: Bool

    private var chipFillStyle: AnyShapeStyle {
        if isFound {
            return AnyShapeStyle(foundGradient)
        }
        return AnyShapeStyle(ColorTokens.chipNeutralFill)
    }

    private var chipStroke: Color {
        ColorTokens.chipBorder
    }

    private var labelColor: Color {
        isFound ? ColorTokens.textPrimary : Color.primary
    }

    private var foundGradient: LinearGradient {
        DailyPuzzleWordGradientPalette.gradient(for: word, seed: styleSeed)
    }

    @ViewBuilder
    var body: some View {
        let chipContent = HStack(spacing: 6) {
            Text(word)
                .font(TypographyTokens.bodyStrong)
                .lineLimit(allowMultiline ? nil : 1)
                .minimumScaleFactor(allowMultiline ? 1 : 0.45)
                .allowsTightening(true)
                .fixedSize(horizontal: false, vertical: allowMultiline)
                .strikethrough(isFound, color: ColorTokens.chipFoundDecoration)
                .foregroundStyle(labelColor)

            if isFound && !allowMultiline {
                Image(systemName: "checkmark.circle.fill")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .symbolEffect(.bounce, value: isFound)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, SpacingTokens.sm)
        .padding(.vertical, SpacingTokens.xs)
        .background(Capsule().fill(chipFillStyle))
        .overlay(
            Capsule()
                .stroke(chipStroke, lineWidth: 1)
        )
        .scaleEffect(isFound ? 1.0 : 0.98)
        .animation(.spring(response: 0.35, dampingFraction: 0.74), value: isFound)

        if expandsHorizontally {
            chipContent
                .frame(maxWidth: .infinity, alignment: allowMultiline ? .leading : .center)
        } else {
            chipContent
        }
    }
}

private struct WrappingFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var x: CGFloat = 0
        var totalHeight: CGFloat = 0
        var lineHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0 && x + size.width > maxWidth {
                usedWidth = max(usedWidth, x - horizontalSpacing)
                totalHeight += lineHeight + verticalSpacing
                x = 0
                lineHeight = 0
            }

            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }

        if !subviews.isEmpty {
            usedWidth = max(usedWidth, max(0, x - horizontalSpacing))
            totalHeight += lineHeight
        }

        let finalWidth = proposal.width ?? usedWidth
        return CGSize(width: finalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > bounds.minX && x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

private enum DailyPuzzleWordGradientPalette {
    private static let goldenStep = 0.61803398875

    #if canImport(UIKit)
    private static func adaptiveHSB(
        hue: Double,
        saturationLight: Double,
        saturationDark: Double,
        brightnessLight: Double,
        brightnessDark: Double
    ) -> Color {
        Color(
            UIColor { trait in
                let isDark = trait.userInterfaceStyle == .dark
                return UIColor(
                    hue: CGFloat(hue),
                    saturation: CGFloat(isDark ? saturationDark : saturationLight),
                    brightness: CGFloat(isDark ? brightnessDark : brightnessLight),
                    alpha: 1
                )
            }
        )
    }
    #else
    private static func adaptiveHSB(
        hue: Double,
        saturationLight: Double,
        saturationDark: Double,
        brightnessLight: Double,
        brightnessDark: Double
    ) -> Color {
        Color(
            hue: hue,
            saturation: saturationLight,
            brightness: brightnessLight,
            opacity: 1
        )
    }
    #endif

    static func gradient(for word: String, seed: Int) -> LinearGradient {
        let normalizedSeed = max(seed, 0)
        let seedHue = (Double(normalizedSeed) * goldenStep).truncatingRemainder(dividingBy: 1)
        let hash = stableHash(word.uppercased())
        let jitter = Double((hash >> 8) % 12) / 260.0
        let hueA = (seedHue + jitter).truncatingRemainder(dividingBy: 1)
        let hueB = (hueA + 0.10 + Double(hash % 10) / 220.0).truncatingRemainder(dividingBy: 1)
        let saturationALight = 0.28 + Double((hash / 97) % 10) / 100.0
        let saturationBLight = 0.22 + Double((hash / 193) % 10) / 100.0
        let saturationADark = min(1.0, saturationALight + 0.16)
        let saturationBDark = min(1.0, saturationBLight + 0.16)

        return LinearGradient(
            colors: [
                adaptiveHSB(
                    hue: hueA,
                    saturationLight: saturationALight,
                    saturationDark: saturationADark,
                    brightnessLight: 0.99,
                    brightnessDark: 0.82
                ),
                adaptiveHSB(
                    hue: hueB,
                    saturationLight: saturationBLight,
                    saturationDark: saturationBDark,
                    brightnessLight: 0.94,
                    brightnessDark: 0.72
                )
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}
