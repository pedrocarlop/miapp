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
            return "Completado"
        }
        return "\(completedWordsCount) de \(totalWords) completadas"
    }

    public var body: some View {
        ZStack {
            DSCard {
                VStack(spacing: SpacingTokens.sm + 6) {
                    VStack(spacing: SpacingTokens.xxs - 2) {
                        Text(Self.weekdayFormatter.string(from: date).capitalized)
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
        .accessibilityLabel("Reto \(puzzleNumber), \(statusLabel)")
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isLocked {
            ZStack {
                Circle()
                    .fill(ColorTokens.surfacePrimary.opacity(0.78))
                    .frame(width: badgeSize, height: badgeSize)
                Image(systemName: "lock.fill")
                    .font(TypographyTokens.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            .allowsHitTesting(false)
        } else if isCompleted {
            ZStack {
                Circle()
                    .fill(ColorTokens.surfacePrimary.opacity(0.78))
                    .frame(width: badgeSize, height: badgeSize)
                Image(systemName: "checkmark.seal.fill")
                    .font(TypographyTokens.titleSmall)
                    .foregroundStyle(ThemeGradients.brushWarm)
            }
            .allowsHitTesting(false)
        }
    }

    private var badgeSize: CGFloat {
        54
    }

    private var lockMessage: String {
        if let hoursUntilAvailable {
            return "Disponible en \(hoursUntilAvailable)h"
        }
        return "Disponible pronto"
    }

    private var monthDayText: String {
        Self.monthDayFormatter.string(from: date).uppercased()
    }

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter
    }()
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
            palette: SharedWordSearchBoardPalette(
                boardBackground: ColorTokens.surfacePaperGrid,
                boardCellBackground: ColorTokens.surfacePaperMuted,
                boardGridStroke: ColorTokens.boardGridStroke,
                boardOuterStroke: ColorTokens.boardOuterStroke,
                letterColor: ColorTokens.textPrimary,
                selectionFill: ColorTokens.selectionFill,
                foundOutlineStroke: ColorTokens.boardGridStroke,
                feedbackCorrect: ColorTokens.feedbackCorrect,
                feedbackIncorrect: ColorTokens.feedbackIncorrect,
                anchorBorder: ColorTokens.accentPrimary
            )
        )
        .scaleEffect(0.96)
    }
}
