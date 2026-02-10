//
//  WordSearchWidget.swift
//  WordSearchWidgetExtension
//

import WidgetKit
import SwiftUI
import AppIntents
import Foundation
import DesignSystem
import Core

@available(iOS 17.0, *)
private enum WordSearchWidgetColorTokens {
    static func widgetBackground(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    ColorTokens.surfaceSecondary,
                    ColorTokens.surfaceTertiary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                ColorTokens.backgroundPrimary,
                ColorTokens.surfaceSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func hintBlockingOverlay(isDark: Bool) -> Color {
        ColorTokens.surfaceSecondary.opacity(isDark ? 0.55 : 0.35)
    }

    static let hintCTA = ColorTokens.accentPrimary
    static let hintPanelStroke = ColorTokens.borderDefault
    static let completionOverlay = ColorTokens.surfaceSecondary.opacity(0.45)
    static let anchorBorderDark = ColorTokens.textPrimary.opacity(0.62)
    static let anchorBorderLight = ColorTokens.textSecondary.opacity(0.75)
}

@available(iOS 17.0, *)
private enum WordSearchWidgetTypographyTokens {
    static let body = TypographyTokens.body
    static let overlayTitle = TypographyTokens.screenTitle.weight(.bold)
    static let overlayBody = TypographyTokens.caption
    static let hintTitle = TypographyTokens.caption.weight(.semibold)
    static let hintBody = TypographyTokens.bodyStrong
    static let hintCTA = TypographyTokens.footnote.weight(.semibold)
}

@available(iOS 17.0, *)
private enum WordSearchWidgetAppearanceMode: String {
    case system
    case light
    case dark

    static func current() -> WordSearchWidgetAppearanceMode {
        switch WordSearchWidgetContainer.shared.settings().appearanceMode {
        case .system:
            return .system
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@available(iOS 17.0, *)
struct WordSearchProvider: TimelineProvider {
    typealias Entry = WordSearchEntry

    func placeholder(in context: Context) -> WordSearchEntry {
        WordSearchEntry(date: Date(), state: WordSearchPersistence.loadState(at: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (WordSearchEntry) -> Void) {
        let state = WordSearchPersistence.loadState(at: Date())
        completion(WordSearchEntry(date: Date(), state: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordSearchEntry>) -> Void) {
        let now = Date()
        let state = WordSearchPersistence.loadState(at: now)
        let entry = WordSearchEntry(date: now, state: state)
        let refreshAt = WordSearchPersistence.nextRefreshDate(from: now, state: state)
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }
}

@available(iOS 17.0, *)
struct WordSearchEntry: TimelineEntry {
    let date: Date
    let state: WordSearchState
}

@available(iOS 17.0, *)
struct WordSearchWidgetEntryView: View {
    let entry: WordSearchEntry
    @Environment(\.colorScheme) private var systemColorScheme

    private var appearanceMode: WordSearchWidgetAppearanceMode {
        WordSearchWidgetAppearanceMode.current()
    }

    private var effectiveColorScheme: ColorScheme {
        switch appearanceMode {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private var widgetBackground: LinearGradient {
        WordSearchWidgetColorTokens.widgetBackground(for: effectiveColorScheme)
    }

    var body: some View {
        WordSearchGridWidget(state: entry.state, colorScheme: effectiveColorScheme)
            .containerBackground(widgetBackground, for: .widget)
            .font(WordSearchWidgetTypographyTokens.body)
    }
}

@available(iOS 17.0, *)
private struct WordSearchGridWidget: View {
    let state: WordSearchState
    let colorScheme: ColorScheme

    private struct WordOutline: Identifiable {
        let id: String
        let word: String
        let seed: Int
        let positions: [WordSearchPosition]
    }
    private let mappedSolvedWordOutlines: [SharedWordSearchBoardOutline]

    init(state: WordSearchState, colorScheme: ColorScheme) {
        self.state = state
        self.colorScheme = colorScheme
        let outlines = Self.makeSolvedWordOutlines(state: state)
        self.mappedSolvedWordOutlines = outlines.map { outline in
            SharedWordSearchBoardOutline(
                id: outline.id,
                word: outline.word,
                seed: outline.seed,
                positions: outline.positions.map { SharedWordSearchBoardPosition(row: $0.r, col: $0.c) }
            )
        }
    }

    private var rows: Int { state.grid.count }
    private var cols: Int { state.grid.first?.count ?? 0 }
    private var isDark: Bool { colorScheme == .dark }
    private var hintMode: WordSearchHintMode {
        WordSearchHintMode.current()
    }
    private var nextRefreshTimeLabel: String {
        WordSearchDailyRefreshSettings.formattedTimeLabel()
    }
    private var isHintBlocking: Bool {
        state.nextHintWord != nil && !state.isCompleted
    }

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = SpacingTokens.xs
            let verticalPadding: CGFloat = SpacingTokens.xs
            let safeRows = max(rows, 1)
            let safeCols = max(cols, 1)
            let availableWidth = max(0, geometry.size.width - horizontalPadding * 2)
            let availableHeight = max(0, geometry.size.height - verticalPadding * 2)
            let cellSize = max(18, min(floor(availableWidth / CGFloat(safeCols)), floor(availableHeight / CGFloat(safeRows))))
            let boardWidth = cellSize * CGFloat(safeCols)
            let boardHeight = cellSize * CGFloat(safeRows)

            ZStack {
                board(cellSize: cellSize)
                    .frame(width: boardWidth, height: boardHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(!isHintBlocking)

                if isHintBlocking {
                    WordSearchWidgetColorTokens.hintBlockingOverlay(isDark: isDark)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }

                nextWordOverlay
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, SpacingTokens.sm)
                    .padding(.top, SpacingTokens.xs)

                if state.isCompleted {
                    completionOverlay
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
    }

    private func board(cellSize: CGFloat) -> some View {
        let displayRows = max(rows, 1)
        let displayCols = max(cols, 1)
        let sideLength = cellSize * CGFloat(displayCols)
        let mappedActive = state.pendingSolvedPositions.map {
            SharedWordSearchBoardPosition(row: $0.r, col: $0.c)
        }
        let mappedFeedback = state.feedback.map { value in
            SharedWordSearchBoardFeedback(
                id: "feedback-\(value.kind.rawValue)-\(value.expiresAt.timeIntervalSince1970)",
                kind: value.kind == .correct ? .correct : .incorrect,
                positions: value.positions.map { SharedWordSearchBoardPosition(row: $0.r, col: $0.c) }
            )
        }
        let mappedAnchor = state.anchor.map { SharedWordSearchBoardPosition(row: $0.r, col: $0.c) }
        let palette = SharedWordSearchBoardPalette(
            boardBackground: ColorTokens.surfacePaperGrid,
            boardCellBackground: ColorTokens.surfacePaperMuted,
            boardGridStroke: ColorTokens.boardGridStroke,
            boardOuterStroke: ColorTokens.boardOuterStroke,
            letterColor: ColorTokens.textPrimary,
            selectionFill: ColorTokens.selectionFill,
            foundOutlineStroke: ColorTokens.textPrimary.opacity(0.82),
            feedbackCorrect: ColorTokens.feedbackCorrect,
            feedbackIncorrect: ColorTokens.feedbackIncorrect,
            anchorBorder: isDark
                ? WordSearchWidgetColorTokens.anchorBorderDark
                : WordSearchWidgetColorTokens.anchorBorderLight
        )

        return ZStack {
            SharedWordSearchBoardView(
                grid: state.grid,
                sideLength: sideLength,
                activePositions: mappedActive,
                feedback: mappedFeedback,
                solvedWordOutlines: mappedSolvedWordOutlines,
                anchor: mappedAnchor,
                palette: palette
            )
            .allowsHitTesting(false)

            tapOverlay(rows: displayRows, cols: displayCols, cellSize: cellSize)
        }
    }

    private func tapOverlay(rows: Int, cols: Int, cellSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<cols, id: \.self) { col in
                        if row < self.rows, col < self.cols {
                            Button(intent: ToggleCellIntent(row: row, col: col)) {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(state.isCompleted)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var nextWordOverlay: some View {
        if let hint = state.nextHintWord, !hint.isEmpty, !state.isCompleted {
            let display = WordSearchWordHints.displayText(for: hint, mode: hintMode)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Siguiente:")
                        .font(WordSearchWidgetTypographyTokens.hintTitle)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Text(display)
                        .font(WordSearchWidgetTypographyTokens.hintBody)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                Button(intent: DismissHintIntent()) {
                    Text("Entendido")
                        .font(WordSearchWidgetTypographyTokens.hintCTA)
                        .padding(.horizontal, SpacingTokens.sm)
                        .padding(.vertical, SpacingTokens.xxs)
                        .background(
                            Capsule()
                                .fill(WordSearchWidgetColorTokens.hintCTA.opacity(isDark ? 0.35 : 0.22))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, SpacingTokens.sm)
            .padding(.vertical, SpacingTokens.xs)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous)
                    .stroke(WordSearchWidgetColorTokens.hintPanelStroke.opacity(isDark ? 0.35 : 1), lineWidth: 0.8)
            )
            .allowsHitTesting(true)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            WordSearchWidgetColorTokens.completionOverlay
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Text("Completado")
                    .font(WordSearchWidgetTypographyTokens.overlayTitle)
                    .multilineTextAlignment(.center)

                Text("Manana a las \(nextRefreshTimeLabel) se cargara otra sopa de letras.")
                    .font(WordSearchWidgetTypographyTokens.overlayBody)
                    .multilineTextAlignment(.center)
                Text("Cada dia se anade un nuevo juego.")
                    .font(WordSearchWidgetTypographyTokens.overlayBody)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SpacingTokens.sm)
            .padding(.vertical, SpacingTokens.sm)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous))
            .padding(SpacingTokens.xl)
        }
    }

    private static func makeSolvedWordOutlines(state: WordSearchState) -> [WordOutline] {
        let normalizedFound = Set(state.foundWords.map { WordSearchNormalization.normalizedWord($0) })
        let grid = Grid(letters: state.grid)

        return state.words.enumerated().compactMap { index, rawWord in
            let normalizedWord = WordSearchNormalization.normalizedWord(rawWord)
            guard normalizedFound.contains(normalizedWord) else { return nil }
            guard let path = WordPathFinderService.bestPath(
                for: normalizedWord,
                grid: grid,
                prioritizing: state.solvedPositions
            ) else { return nil }
            let signature = path.map { "\($0.r)-\($0.c)" }.joined(separator: "_")
            return WordOutline(
                id: "\(index)-\(normalizedWord)-\(signature)",
                word: normalizedWord,
                seed: index,
                positions: path
            )
        }
    }
}

@available(iOS 17.0, *)
struct WordSearchWidget: Widget {
    let kind: String = WordSearchConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordSearchProvider()) { entry in
            WordSearchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sopa de letras")
        .description("Selecciona una letra inicial y una final para cada palabra.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
