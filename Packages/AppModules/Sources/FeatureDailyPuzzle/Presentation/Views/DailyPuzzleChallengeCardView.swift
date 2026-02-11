/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleChallengeCardView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleChallengeCardView,DailyPuzzleChallengeCardGridPreview
 - Funciones clave en este archivo: (sin funciones directas visibles; revisa propiedades/constantes/extensiones)
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

public struct DailyPuzzleChallengeCardView: View {
    public let date: Date
    public let puzzleNumber: Int
    public let grid: [[String]]
    public let words: [String]
    public let foundWords: Set<String>
    public let solvedPositions: Set<GridPosition>
    public let isLocked: Bool
    public let hoursUntilAvailable: Int?
    public let isLaunching: Bool
    public let onPlay: () -> Void

    public init(
        date: Date,
        puzzleNumber: Int,
        grid: [[String]],
        words: [String],
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>,
        isLocked: Bool,
        hoursUntilAvailable: Int?,
        isLaunching: Bool,
        onPlay: @escaping () -> Void
    ) {
        self.date = date
        self.puzzleNumber = puzzleNumber
        self.grid = grid
        self.words = words
        self.foundWords = foundWords
        self.solvedPositions = solvedPositions
        self.isLocked = isLocked
        self.hoursUntilAvailable = hoursUntilAvailable
        self.isLaunching = isLaunching
        self.onPlay = onPlay
    }

    private var totalWords: Int {
        words.count
    }

    private var completedWordsCount: Int {
        min(foundWords.count, totalWords)
    }

    private var isCompleted: Bool {
        totalWords > 0 && completedWordsCount >= totalWords
    }

    private var shouldDimPreview: Bool {
        isCompleted || isLocked
    }

    private var statusLabel: String {
        if isLocked {
            return lockMessage
        }
        if isCompleted {
            return DailyPuzzleStrings.completed
        }
        return DailyPuzzleStrings.challengeProgress(found: completedWordsCount, total: totalWords)
    }

    public var body: some View {
        ZStack {
            DSCard {
                VStack(spacing: SpacingTokens.sm + 6) {
                    header

                    GeometryReader { geometry in
                        let gridSide = min(geometry.size.width, geometry.size.height)

                        DailyPuzzleChallengeCardGridPreview(
                            grid: grid,
                            words: words,
                            foundWords: foundWords,
                            solvedPositions: solvedPositions,
                            sideLength: gridSide
                        )
                        .frame(width: gridSide, height: gridSide)
                        .saturation(shouldDimPreview ? 0.22 : 1)
                        .opacity(shouldDimPreview ? 0.72 : 1)
                        .blur(radius: shouldDimPreview ? 3 : 0)
                        .overlay(alignment: .center) {
                            statusBadge
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(isLaunching ? 1.08 : 1)
                        .animation(.easeInOut(duration: MotionTokens.normalDuration), value: isLaunching)
                    }
                    .frame(height: 240)

                    Text(statusLabel)
                        .font(TypographyTokens.footnote.weight(.semibold))
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous)
                    .stroke(ColorTokens.cardHighlightStroke, lineWidth: 1.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous)
                    .stroke(ColorTokens.borderDefault, lineWidth: 1)
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous))
        .onTapGesture {
            guard !isCompleted else { return }
            onPlay()
        }
        .scaleEffect(isLaunching ? 1.02 : 1)
        .animation(.easeInOut(duration: MotionTokens.fastDuration), value: isLocked)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(DailyPuzzleStrings.challengeAccessibilityLabel(number: puzzleNumber, status: statusLabel))
    }

    private var header: some View {
        VStack(spacing: SpacingTokens.xxs - 2) {
            Text(weekdayText)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            Text(monthDayText)
                .font(TypographyTokens.displayTitle)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isLocked {
            DSStatusBadge(kind: .locked, size: badgeSize)
        } else if isCompleted {
            DSStatusBadge(kind: .completed, size: badgeSize)
        }
    }

    private var badgeSize: CGFloat {
        54
    }

    private var lockMessage: String {
        if let hoursUntilAvailable {
            return DailyPuzzleStrings.challengeAvailableIn(hours: hoursUntilAvailable)
        }
        return DailyPuzzleStrings.challengeAvailableSoon
    }

    private var monthDayText: String {
        let locale = AppLocalization.currentLocale
        return date
            .formatted(
                .dateTime
                    .locale(locale)
                    .day()
                    .month(.abbreviated)
            )
            .uppercased(with: locale)
    }

    private var weekdayText: String {
        let locale = AppLocalization.currentLocale
        return date
            .formatted(
                .dateTime
                    .locale(locale)
                    .weekday(.wide)
            )
            .capitalized(with: locale)
    }
}

private struct DailyPuzzleChallengeCardGridPreview: View {
    let grid: [[String]]
    let words: [String]
    let foundWords: Set<String>
    let solvedPositions: Set<GridPosition>
    let sideLength: CGFloat

    private var outlines: [SharedWordSearchBoardOutline] {
        let normalizedFoundWords = Set(foundWords.map(WordSearchNormalization.normalizedWord))
        let coreGrid = Core.PuzzleGrid(letters: grid)

        return words.enumerated().compactMap { index, word in
            let normalized = WordSearchNormalization.normalizedWord(word)
            guard normalizedFoundWords.contains(normalized) else { return nil }
            guard let path = WordPathFinderService.bestPath(
                for: normalized,
                grid: coreGrid,
                prioritizing: solvedPositions
            ) else {
                return nil
            }
            let boardPath = path.map { SharedWordSearchBoardPosition(row: $0.row, col: $0.col) }
            return SharedWordSearchBoardOutline(
                id: "preview-\(index)-\(normalized)",
                word: normalized,
                seed: index,
                positions: boardPath
            )
        }
    }

    var body: some View {
        SharedWordSearchBoardView(
            grid: grid,
            sideLength: sideLength,
            activePositions: [],
            feedback: nil,
            solvedWordOutlines: outlines,
            anchor: nil,
            palette: WordSearchBoardStylePreset.challengePreview
        )
        .scaleEffect(0.96)
    }
}

#Preview("Challenge Card States") {
    PreviewThemeProvider {
        VStack(spacing: SpacingTokens.md) {
            DailyPuzzleChallengeCardView(
                date: .now,
                puzzleNumber: 1,
                grid: Array(repeating: Array(repeating: "A", count: 8), count: 8),
                words: ["ARBOL", "RIO", "LUNA", "NUBE"],
                foundWords: ["ARBOL"],
                solvedPositions: [],
                isLocked: false,
                hoursUntilAvailable: nil,
                isLaunching: false
            ) {}
            .frame(width: 320, height: 360)

            DailyPuzzleChallengeCardView(
                date: .now.addingTimeInterval(86_400),
                puzzleNumber: 2,
                grid: Array(repeating: Array(repeating: "B", count: 8), count: 8),
                words: ["ARBOL", "RIO", "LUNA", "NUBE"],
                foundWords: [],
                solvedPositions: [],
                isLocked: true,
                hoursUntilAvailable: 5,
                isLaunching: false
            ) {}
            .frame(width: 320, height: 360)
        }
    }
}
