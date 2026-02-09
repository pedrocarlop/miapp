//
//  WordSearchWidget.swift
//  WordSearchWidgetExtension
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
private enum WordSearchWidgetColorTokens {
    static func widgetBackground(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color(.tertiarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color(.systemGray6),
                Color(.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func lineColor(isDark: Bool) -> Color {
        isDark ? Color.secondary.opacity(0.34) : Color.secondary.opacity(0.24)
    }

    static func solvedWordBorder(isDark: Bool) -> Color {
        Color.accentColor.opacity(isDark ? 0.94 : 0.84)
    }

    static func boardFill(isDark: Bool) -> Color {
        Color(.secondarySystemBackground).opacity(isDark ? 0.30 : 0.55)
    }

    static func boardStroke(isDark: Bool) -> Color {
        Color.primary.opacity(isDark ? 0.24 : 0.18)
    }

    static func letterColor(isDark: Bool) -> Color {
        isDark ? Color.primary.opacity(0.94) : Color.primary
    }

    static func hintBlockingOverlay(isDark: Bool) -> Color {
        Color(.secondarySystemFill).opacity(isDark ? 0.55 : 0.35)
    }

    static let hintCTA = Color.accentColor
    static let hintPanelStroke = Color.primary.opacity(0.25)
    static let completionOverlay = Color(.secondarySystemFill).opacity(0.45)
    static let anchorBorderDark = Color.primary.opacity(0.62)
    static let anchorBorderLight = Color.secondary.opacity(0.75)
    static let feedbackCorrect = Color(.systemGreen)
    static let feedbackIncorrect = Color(.systemRed)
}

@available(iOS 17.0, *)
private enum WordSearchWidgetAppearanceMode: String {
    case system
    case light
    case dark

    static func current(defaults: UserDefaults?) -> WordSearchWidgetAppearanceMode {
        guard let defaults else { return .system }
        guard let raw = defaults.string(forKey: WordSearchConstants.appearanceModeKey) else { return .system }
        return WordSearchWidgetAppearanceMode(rawValue: raw) ?? .system
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
        WordSearchWidgetAppearanceMode.current(defaults: UserDefaults(suiteName: WordSearchConstants.suiteName))
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
    }
}

@available(iOS 17.0, *)
private struct WordSearchGridWidget: View {
    let state: WordSearchState
    let colorScheme: ColorScheme

    private struct WordOutline: Identifiable {
        let id: String
        let positions: [WordSearchPosition]
    }

    private let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]

    private var rows: Int { state.grid.count }
    private var cols: Int { state.grid.first?.count ?? 0 }
    private var isDark: Bool { colorScheme == .dark }
    private var lineColor: Color { WordSearchWidgetColorTokens.lineColor(isDark: isDark) }
    private var solvedWordBorder: Color { WordSearchWidgetColorTokens.solvedWordBorder(isDark: isDark) }
    private var boardFill: Color { WordSearchWidgetColorTokens.boardFill(isDark: isDark) }
    private var boardStroke: Color { WordSearchWidgetColorTokens.boardStroke(isDark: isDark) }
    private var letterColor: Color { WordSearchWidgetColorTokens.letterColor(isDark: isDark) }
    private var hintMode: WordSearchHintMode {
        WordSearchHintMode.current(defaults: UserDefaults(suiteName: WordSearchConstants.suiteName))
    }
    private var isHintBlocking: Bool {
        state.nextHintWord != nil && !state.isCompleted
    }

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 8
            let verticalPadding: CGFloat = 8
            let safeRows = max(rows, 1)
            let safeCols = max(cols, 1)
            let availableWidth = max(0, geometry.size.width - horizontalPadding * 2)
            let availableHeight = max(0, geometry.size.height - verticalPadding * 2)
            let cellSize = max(18, min(floor(availableWidth / CGFloat(safeCols)), floor(availableHeight / CGFloat(safeRows))))
            let boardWidth = cellSize * CGFloat(safeCols)
            let boardHeight = cellSize * CGFloat(safeRows)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(boardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(boardStroke, lineWidth: 0.8)
                    )
                    .frame(width: boardWidth, height: boardHeight)

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
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

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
        let letterSize = max(9, cellSize * 0.48)

        return ZStack {
            VStack(spacing: 0) {
                ForEach(0..<displayRows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<displayCols, id: \.self) { col in
                            if row < rows, col < cols {
                                let position = WordSearchPosition(r: row, c: col)
                                let value = state.grid[row][col]

                                Button(intent: ToggleCellIntent(row: row, col: col)) {
                                    Text(value)
                                        .font(.system(size: letterSize, weight: .medium, design: .rounded))
                                        .frame(width: cellSize, height: cellSize)
                                        .foregroundStyle(letterColor)
                                        .background(cellFill(for: position))
                                        .overlay(
                                            Rectangle()
                                                .stroke(
                                                    cellBorderColor(for: position),
                                                    lineWidth: cellBorderWidth(for: position)
                                                )
                                        )
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

            GridLines(rows: displayRows, cols: displayCols)
                .stroke(lineColor, lineWidth: 1)

            foundWordOutlines(cellSize: cellSize)
                .allowsHitTesting(false)

            feedbackOutline(cellSize: cellSize)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var nextWordOverlay: some View {
        if let hint = state.nextHintWord, !hint.isEmpty, !state.isCompleted {
            let display = WordSearchWordHints.displayText(for: hint, mode: hintMode)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Siguiente:")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(display)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                Button(intent: DismissHintIntent()) {
                    Text("Entendido")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(WordSearchWidgetColorTokens.hintCTA.opacity(isDark ? 0.35 : 0.22))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Manana a las 9 se cargara otra sopa de letras.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Cada dia se anade un nuevo juego.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(24)
        }
    }

    private func cellFill(for position: WordSearchPosition) -> Color {
        .clear
    }

    private func cellBorderColor(for position: WordSearchPosition) -> Color {
        if state.anchor == position {
            return isDark ? WordSearchWidgetColorTokens.anchorBorderDark : WordSearchWidgetColorTokens.anchorBorderLight
        }
        return .clear
    }

    private func cellBorderWidth(for position: WordSearchPosition) -> CGFloat {
        if let feedback = state.feedback, feedback.positions.contains(position) {
            return 0
        }
        if state.anchor == position {
            return 1.8
        }
        return 0
    }

    @ViewBuilder
    private func feedbackOutline(cellSize: CGFloat) -> some View {
        if let feedback = state.feedback,
           let first = feedback.positions.first,
           let last = feedback.positions.last {
            let capsuleHeight = cellSize * 0.82
            let lineWidth = max(1.8, min(3.6, cellSize * 0.12))
            let color = feedback.kind == .correct
                ? WordSearchWidgetColorTokens.feedbackCorrect
                : WordSearchWidgetColorTokens.feedbackIncorrect
            StretchingCapsule(
                start: center(for: first, cellSize: cellSize),
                end: center(for: last, cellSize: cellSize),
                capsuleHeight: capsuleHeight,
                lineWidth: lineWidth,
                color: color
            )
            .id("feedback-\(feedback.kind.rawValue)-\(feedback.expiresAt.timeIntervalSince1970)")
        } else {
            EmptyView()
        }
    }

    private func foundWordOutlines(cellSize: CGFloat) -> some View {
        let capsuleHeight = cellSize * 0.82
        let lineWidth = max(1.5, min(3.0, cellSize * 0.10))

        return ZStack {
            ForEach(solvedWordOutlines) { outline in
                outlineShape(
                    for: outline.positions,
                    cellSize: cellSize,
                    capsuleHeight: capsuleHeight,
                    lineWidth: lineWidth
                )
            }
        }
    }

    @ViewBuilder
    private func outlineShape(
        for positions: [WordSearchPosition],
        cellSize: CGFloat,
        capsuleHeight: CGFloat,
        lineWidth: CGFloat
    ) -> some View {
        if let first = positions.first, let last = positions.last {
            let start = center(for: first, cellSize: cellSize)
            let end = center(for: last, cellSize: cellSize)
            let dx = end.x - start.x
            let dy = end.y - start.y
            let angle = Angle(radians: atan2(dy, dx))
            let centerPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

            Capsule(style: .continuous)
                .stroke(solvedWordBorder, lineWidth: lineWidth)
                .frame(width: capsuleWidth, height: capsuleHeight)
                .rotationEffect(angle)
                .position(centerPoint)
        }
    }

    private func center(for position: WordSearchPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.c) * cellSize + cellSize / 2,
            y: CGFloat(position.r) * cellSize + cellSize / 2
        )
    }

    private var solvedWordOutlines: [WordOutline] {
        let foundWords = Set(state.foundWords.map { $0.uppercased() })

        return state.words.enumerated().compactMap { index, rawWord in
            let word = rawWord.uppercased()
            guard foundWords.contains(word) else { return nil }
            guard let path = bestPath(for: word) else { return nil }
            let signature = path.map { "\($0.r)-\($0.c)" }.joined(separator: "_")
            return WordOutline(
                id: "\(index)-\(word)-\(signature)",
                positions: path
            )
        }
    }

    private func bestPath(for word: String) -> [WordSearchPosition]? {
        let candidates = candidatePaths(for: word)
        guard !candidates.isEmpty else { return nil }
        return candidates.max { pathScore($0) < pathScore($1) }
    }

    private func pathScore(_ path: [WordSearchPosition]) -> Int {
        path.reduce(0) { partial, position in
            partial + (state.solvedPositions.contains(position) ? 1 : 0)
        }
    }

    private func candidatePaths(for word: String) -> [[WordSearchPosition]] {
        let upperWord = word.uppercased()
        let letters = upperWord.map { String($0) }
        let reversed = Array(letters.reversed())
        guard !letters.isEmpty else { return [] }
        guard rows > 0, cols > 0 else { return [] }

        var results: [[WordSearchPosition]] = []

        for row in 0..<rows {
            for col in 0..<cols {
                for (dr, dc) in directions {
                    var path: [WordSearchPosition] = []
                    var collected: [String] = []
                    var isValid = true

                    for step in 0..<letters.count {
                        let r = row + step * dr
                        let c = col + step * dc
                        if r < 0 || c < 0 || r >= rows || c >= cols {
                            isValid = false
                            break
                        }
                        path.append(WordSearchPosition(r: r, c: c))
                        collected.append(state.grid[r][c].uppercased())
                    }

                    guard isValid else { continue }
                    if collected == letters || collected == reversed {
                        results.append(path)
                    }
                }
            }
        }

        return results
    }
}

@available(iOS 17.0, *)
private struct StretchingCapsule: View {
    let start: CGPoint
    let end: CGPoint
    let capsuleHeight: CGFloat
    let lineWidth: CGFloat
    let color: Color

    @State private var animate = false

    var body: some View {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = Angle(radians: atan2(dy, dx))
        let centerPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

        return Capsule(style: .continuous)
            .stroke(color, lineWidth: lineWidth)
            .frame(width: capsuleWidth, height: capsuleHeight)
            .scaleEffect(x: animate ? 1 : 0.05, y: 1, anchor: .leading)
            .rotationEffect(angle)
            .position(centerPoint)
            .onAppear {
                withAnimation(.easeOut(duration: 0.22)) {
                    animate = true
                }
            }
    }
}

@available(iOS 17.0, *)
private struct GridLines: Shape {
    let rows: Int
    let cols: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard rows > 0, cols > 0 else { return path }

        let rowHeight = rect.height / CGFloat(rows)
        let colWidth = rect.width / CGFloat(cols)

        for row in 0...rows {
            let y = CGFloat(row) * rowHeight
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        for col in 0...cols {
            let x = CGFloat(col) * colWidth
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        return path
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
