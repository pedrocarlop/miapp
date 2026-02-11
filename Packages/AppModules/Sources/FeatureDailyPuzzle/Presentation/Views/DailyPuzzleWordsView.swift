/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleWordsView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleWordsView,WordChip WrappingFlowLayout
 - Funciones clave en este archivo: sizeThatFits,placeSubviews
 - Como leerlo sin experiencia:
   1) Busca primero los tipos clave para entender 'quien vive aqui'.
   2) Revisa propiedades (let/var): indican que datos mantiene cada tipo.
   3) Sigue funciones publicas: son la puerta de entrada para otras capas.
   4) Luego mira funciones privadas: implementan detalles internos paso a paso.
   5) Si ves guard/if/switch, son decisiones que controlan el flujo.
 - Recordatorio rapido de sintaxis:
   - let = valor fijo; var = valor que puede cambiar.
   - guard = valida pronto; si falla, sale de la funcion.
   - return = devuelve un resultado y cierra esa funcion.
*/

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
                        ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                            let displayText = WordHintsService.displayText(for: word, mode: displayMode)
                            WordChip(
                                word: displayText,
                                isFound: foundWords.contains(word.uppercased()),
                                allowMultiline: true,
                                expandsHorizontally: true
                            )
                        }
                    }
                    .padding(.trailing, SpacingTokens.xxs)
                } else {
                    WrappingFlowLayout(horizontalSpacing: SpacingTokens.xs, verticalSpacing: SpacingTokens.xs) {
                        ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                            let displayText = WordHintsService.displayText(for: word, mode: displayMode)
                            WordChip(
                                word: displayText,
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
        .mask(alignment: .top) {
            VStack(spacing: 0) {
                ThemeGradients.wordListTopFade
                    .frame(height: topFadeHeight)
                Rectangle()
                    .fill(Color.black)
            }
        }
    }
}

private struct WordChip: View {
    let word: String
    let isFound: Bool
    let allowMultiline: Bool
    let expandsHorizontally: Bool

    private var chipFillStyle: AnyShapeStyle {
        if isFound {
            return AnyShapeStyle(ThemeGradients.brushWarm.opacity(0.26))
        }
        return AnyShapeStyle(ColorTokens.chipNeutralFill)
    }

    private var chipStroke: Color {
        isFound ? ColorTokens.accentCoralStrong.opacity(0.55) : ColorTokens.chipBorder
    }

    private var labelColor: Color {
        isFound ? ColorTokens.inkPrimary : ColorTokens.textPrimary
    }

    @ViewBuilder
    var body: some View {
        let chipContent = HStack(spacing: 6) {
            Text(word)
                .font(allowMultiline ? TypographyTokens.wordDescription : TypographyTokens.wordChip)
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
        .background(
            RoundedRectangle(cornerRadius: RadiusTokens.chipRadius, style: .continuous)
                .fill(chipFillStyle)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RadiusTokens.chipRadius, style: .continuous)
                .stroke(chipStroke, lineWidth: 1)
        )
        .scaleEffect(isFound ? 1.0 : 0.98)
        .animation(MotionTokens.celebrate, value: isFound)

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
