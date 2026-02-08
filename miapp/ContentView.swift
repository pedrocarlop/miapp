//
//  ContentView.swift
//  miapp
//
//  Created by Pedro Carrasco lopez brea on 8/2/26.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showResetConfirmation = false
    @State private var showSettings = false
    @State private var installDate = HostPuzzleCalendar.installationDate()
    @State private var selectedOffset: Int?
    @State private var gridSize = HostDifficultySettings.gridSize()
    @State private var appearanceMode = HostAppearanceSettings.mode()
    @State private var widgetProgress = HostWidgetProgressStore.loadSnapshot()

    private var todayOffset: Int {
        HostPuzzleCalendar.dayOffset(from: installDate, to: Date())
    }

    private var minOffset: Int { 0 }
    private var maxOffset: Int { todayOffset + 1 }

    private var availableOffsets: [Int] {
        guard minOffset <= maxOffset else { return [todayOffset] }
        return Array(minOffset...maxOffset)
    }

    private var selectedSafeOffset: Int {
        min(max(selectedOffset ?? todayOffset, minOffset), maxOffset)
    }

    private var visibleDotOffsets: [Int] {
        if availableOffsets.count <= 3 {
            return availableOffsets
        }
        let start = min(max(selectedSafeOffset - 1, minOffset), maxOffset - 2)
        return [start, start + 1, start + 2]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                GeometryReader { geometry in
                    let cardWidth = min(geometry.size.width * 0.90, 720)
                    let reservedHeight: CGFloat = 170
                    let cardHeight = max(460, geometry.size.height - reservedHeight)
                    let sidePadding = max((geometry.size.width - cardWidth) / 2, 0)

                    VStack(spacing: 16) {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 14) {
                                ForEach(availableOffsets, id: \.self) { offset in
                                    let puzzle = puzzleForOffset(offset)
                                    let progress = progressForOffset(offset, puzzle: puzzle)
                                    PuzzleDayCard(
                                        date: HostPuzzleCalendar.date(from: installDate, dayOffset: offset),
                                        dayOffset: offset,
                                        todayOffset: todayOffset,
                                        puzzle: puzzle,
                                        progress: progress,
                                        isLocked: offset > todayOffset
                                    )
                                    .frame(width: cardWidth, height: cardHeight)
                                    .id(offset)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, sidePadding)
                            .padding(.top, 6)
                        }
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                        .scrollPosition(id: $selectedOffset, anchor: .center)

                        CarouselDotsView(
                            offsets: visibleDotOffsets,
                            selectedOffset: selectedSafeOffset
                        )
                        .padding(.bottom, 6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .safeAreaInset(edge: .top, spacing: 10) {
                        HStack {
                            Spacer()
                            Menu {
                                Button {
                                    showSettings = true
                                } label: {
                                    Label("Settings", systemImage: "slider.horizontal.3")
                                }

                                Button(role: .destructive) {
                                    HostMaintenance.resetCurrentPuzzle()
                                    showResetConfirmation = true
                                } label: {
                                    Label("Reiniciar puzzle", systemImage: "arrow.counterclockwise")
                                }
                            } label: {
                                GlassIconLabel(systemImage: "ellipsis")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .onAppear {
                installDate = HostPuzzleCalendar.installationDate()
                gridSize = HostDifficultySettings.gridSize()
                appearanceMode = HostAppearanceSettings.mode()
                widgetProgress = HostWidgetProgressStore.loadSnapshot()
                selectedOffset = todayOffset
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                installDate = HostPuzzleCalendar.installationDate()
                gridSize = HostDifficultySettings.gridSize()
                appearanceMode = HostAppearanceSettings.mode()
                widgetProgress = HostWidgetProgressStore.loadSnapshot()
            }
            .onChange(of: selectedOffset) { _, value in
                guard let value else { return }
                if value > maxOffset {
                    selectedOffset = maxOffset
                }
            }
            .sheet(isPresented: $showSettings) {
                DifficultySettingsView(
                    currentGridSize: gridSize,
                    currentAppearanceMode: appearanceMode
                ) { newGridSize, newAppearanceMode in
                    let clamped = HostDifficultySettings.clampGridSize(newGridSize)

                    if clamped != gridSize {
                        gridSize = clamped
                        HostMaintenance.applyGridSize(clamped)
                    }

                    if newAppearanceMode != appearanceMode {
                        appearanceMode = newAppearanceMode
                        HostMaintenance.applyAppearance(newAppearanceMode)
                    }

                    widgetProgress = HostWidgetProgressStore.loadSnapshot()
                }
            }
            .alert("Partida reiniciada", isPresented: $showResetConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("El widget recargara el puzzle actual sin progreso.")
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private func puzzleForOffset(_ offset: Int) -> HostPuzzle {
        let generated = HostPuzzleCalendar.puzzle(forDayOffset: offset, gridSize: gridSize)
        guard offset == todayOffset, let progress = widgetProgress else {
            return generated
        }
        guard !progress.grid.isEmpty, !progress.words.isEmpty else {
            return generated
        }
        return HostPuzzle(number: generated.number, grid: progress.grid, words: progress.words)
    }

    private func progressForOffset(_ offset: Int, puzzle: HostPuzzle) -> HostPuzzleProgress {
        guard offset == todayOffset, let progress = widgetProgress else {
            return .empty
        }

        let puzzleWords = Set(puzzle.words.map { $0.uppercased() })
        let foundWords = progress.foundWords.intersection(puzzleWords)
        let maxRow = puzzle.grid.count
        let maxCol = puzzle.grid.first?.count ?? 0
        let solvedCells = progress.solvedPositions.filter { position in
            position.row >= 0 && position.col >= 0 && position.row < maxRow && position.col < maxCol
        }

        return HostPuzzleProgress(
            foundWords: foundWords,
            solvedPositions: Set(solvedCells)
        )
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemGray6),
                    Color(.secondarySystemBackground),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 380, height: 380)
                .blur(radius: 70)
                .offset(x: -130, y: -260)
            Circle()
                .fill(Color.blue.opacity(0.14))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: 170, y: 260)
        }
        .ignoresSafeArea()
    }
}

private struct PuzzleDayCard: View {
    let date: Date
    let dayOffset: Int
    let todayOffset: Int
    let puzzle: HostPuzzle
    let progress: HostPuzzleProgress
    let isLocked: Bool

    private let cardCornerRadius: CGFloat = 34

    private var progressText: String {
        guard !puzzle.words.isEmpty else { return "--" }
        return "\(progress.foundWords.count) de \(puzzle.words.count) encontradas"
    }

    private var titleText: String {
        if dayOffset == todayOffset {
            return "Hoy, \(date.formatted(.dateTime.day().month(.abbreviated).year()))"
        }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    var body: some View {
        ZStack {
            GeometryReader { cardGeo in
                let horizontalPadding: CGFloat = 24
                let verticalPadding: CGFloat = 22
                let titleHeight: CGFloat = 72
                let progressHeight: CGFloat = 20
                let chipRows = max(1, Int(ceil(Double(puzzle.words.count) / 2.0)))
                let estimatedWordsHeight = CGFloat(chipRows * 42 + max(chipRows - 1, 0) * 8)
                let wordsHeight = min(max(estimatedWordsHeight, 132), 180)
                let spacingTitleToGrid: CGFloat = 18
                let spacingGridToProgress: CGFloat = 14
                let spacingProgressToWords: CGFloat = 12
                let availableGridWidth = max(0, cardGeo.size.width - horizontalPadding * 2)
                let availableGridHeight = max(
                    0,
                    cardGeo.size.height
                        - verticalPadding * 2
                        - titleHeight
                        - progressHeight
                        - wordsHeight
                        - spacingTitleToGrid
                        - spacingGridToProgress
                        - spacingProgressToWords
                )
                let gridSide = max(1, min(availableGridWidth, availableGridHeight))

                VStack(spacing: 0) {
                    Text(titleText.capitalized)
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.38)
                        .frame(maxWidth: .infinity, minHeight: titleHeight, maxHeight: titleHeight, alignment: .center)

                    PuzzleGridPreview(
                        grid: puzzle.grid,
                        words: puzzle.words,
                        foundWords: progress.foundWords,
                        solvedPositions: progress.solvedPositions,
                        sideLength: gridSide
                    )
                    .frame(width: gridSide, height: gridSide, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, spacingTitleToGrid)

                    Text(progressText)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: progressHeight, maxHeight: progressHeight, alignment: .leading)
                        .padding(.horizontal, 4)
                        .padding(.top, spacingGridToProgress)
                        .foregroundStyle(.secondary)

                    PuzzleWordsPreview(
                        words: puzzle.words,
                        foundWords: progress.foundWords
                    )
                    .frame(height: wordsHeight)
                    .padding(.top, spacingProgressToWords)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .stroke(Color.gray.opacity(0.26), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
            .blur(radius: isLocked ? 6 : 0)

            if isLocked {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                    )
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24, weight: .bold))
                            Text("Bloqueado")
                                .font(.headline.weight(.bold))
                            Text("Disponible manana")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLocked)
    }
}

private struct CarouselDotsView: View {
    let offsets: [Int]
    let selectedOffset: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(offsets, id: \.self) { offset in
                Circle()
                    .fill(offset == selectedOffset ? Color.primary.opacity(0.34) : Color.primary.opacity(0.14))
                    .frame(
                        width: offset == selectedOffset ? 11 : 8,
                        height: offset == selectedOffset ? 11 : 8
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.45), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct GlassIconLabel: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 46, height: 46)
            .foregroundStyle(.primary)
            .background(
            Circle()
                .fill(.ultraThinMaterial)
            )
            .overlay(
            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .accessibilityLabel(systemImage)
    }
}

private struct PuzzleGridPreview: View {
    let grid: [[String]]
    let words: [String]
    let foundWords: Set<String>
    let solvedPositions: Set<HostGridPosition>
    let sideLength: CGFloat
    
    private struct WordOutline: Identifiable {
        let id: String
        let positions: [HostGridPosition]
    }

    private let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]

    var body: some View {
        let size = max(grid.count, 1)
        let cellSize = sideLength / CGFloat(size)
        let fontSize = max(8, min(24, cellSize * 0.48))
        let gridShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return ZStack {
            VStack(spacing: 0) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<size, id: \.self) { col in
                            let value = row < grid.count && col < grid[row].count ? grid[row][col] : ""
                            let position = HostGridPosition(row: row, col: col)
                            Text(value)
                                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                                .frame(width: cellSize, height: cellSize)
                                .background(
                                    solvedPositions.contains(position) ? Color.blue.opacity(0.16) : .clear
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.23), lineWidth: 1)
                                )
                        }
                    }
                }
            }

            foundWordOutlines(cellSize: cellSize)
        }
        .frame(width: sideLength, height: sideLength, alignment: .center)
        .clipShape(gridShape)
        .overlay(
            gridShape
                .stroke(Color.gray.opacity(0.28), lineWidth: 1)
        )
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
        for positions: [HostGridPosition],
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
                .stroke(Color.blue.opacity(0.86), lineWidth: lineWidth)
                .frame(width: capsuleWidth, height: capsuleHeight)
                .rotationEffect(angle)
                .position(centerPoint)
        }
    }

    private func center(for position: HostGridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }

    private var solvedWordOutlines: [WordOutline] {
        let normalizedFoundWords = Set(foundWords.map { $0.uppercased() })

        return words.enumerated().compactMap { index, rawWord in
            let word = rawWord.uppercased()
            guard normalizedFoundWords.contains(word) else { return nil }
            guard let path = bestPath(for: word) else { return nil }
            let signature = path.map { "\($0.row)-\($0.col)" }.joined(separator: "_")
            return WordOutline(
                id: "\(index)-\(word)-\(signature)",
                positions: path
            )
        }
    }

    private func bestPath(for word: String) -> [HostGridPosition]? {
        let candidates = candidatePaths(for: word)
        guard !candidates.isEmpty else { return nil }
        return candidates.max { pathScore($0) < pathScore($1) }
    }

    private func pathScore(_ path: [HostGridPosition]) -> Int {
        path.reduce(0) { partial, position in
            partial + (solvedPositions.contains(position) ? 1 : 0)
        }
    }

    private func candidatePaths(for word: String) -> [[HostGridPosition]] {
        let upperWord = word.uppercased()
        let letters = upperWord.map { String($0) }
        let reversed = Array(letters.reversed())
        let rowCount = grid.count
        let colCount = grid.first?.count ?? 0

        guard !letters.isEmpty else { return [] }
        guard rowCount > 0, colCount > 0 else { return [] }

        var results: [[HostGridPosition]] = []

        for row in 0..<rowCount {
            for col in 0..<colCount {
                for (dr, dc) in directions {
                    var path: [HostGridPosition] = []
                    var collected: [String] = []
                    var isValid = true

                    for step in 0..<letters.count {
                        let r = row + step * dr
                        let c = col + step * dc
                        if r < 0 || c < 0 || r >= rowCount || c >= colCount {
                            isValid = false
                            break
                        }
                        path.append(HostGridPosition(row: r, col: c))
                        collected.append(grid[r][c].uppercased())
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

private struct PuzzleWordsPreview: View {
    let words: [String]
    let foundWords: Set<String>

    private let columns = [
        GridItem(.flexible(minimum: 120), spacing: 8),
        GridItem(.flexible(minimum: 120), spacing: 8)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    WordChip(
                        word: word,
                        isFound: foundWords.contains(word.uppercased())
                    )
                }
            }
            .padding(.trailing, 4)
        }
    }

    private struct WordChip: View {
        let word: String
        let isFound: Bool

        private var chipFill: Color {
            isFound ? Color.green.opacity(0.16) : Color.white.opacity(0.32)
        }

        private var chipStroke: Color {
            isFound ? Color.green.opacity(0.42) : Color.gray.opacity(0.30)
        }

        private var labelColor: Color {
            isFound ? Color.green.opacity(0.9) : .primary
        }

        var body: some View {
            Text(word)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .allowsTightening(true)
                .strikethrough(isFound, color: .green)
                .foregroundStyle(labelColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Capsule().fill(chipFill))
                .overlay(
                    Capsule()
                        .stroke(chipStroke, lineWidth: 1)
                )
        }
    }
}

private struct DifficultySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gridSize: Int
    @State private var appearanceMode: HostAppearanceMode
    let onSave: (Int, HostAppearanceMode) -> Void

    init(
        currentGridSize: Int,
        currentAppearanceMode: HostAppearanceMode,
        onSave: @escaping (Int, HostAppearanceMode) -> Void
    ) {
        _gridSize = State(initialValue: HostDifficultySettings.clampGridSize(currentGridSize))
        _appearanceMode = State(initialValue: currentAppearanceMode)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dificultad") {
                    Stepper(value: $gridSize, in: HostDifficultySettings.minGridSize...HostDifficultySettings.maxGridSize) {
                        Text("Tamano de sopa: \(gridSize)x\(gridSize)")
                    }
                    Text("A mayor tamano, mas dificultad. En el widget las letras y el area tactil se reducen para que entre la cuadricula.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apariencia") {
                    Picker("Tema", selection: $appearanceMode) {
                        ForEach(HostAppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(gridSize, appearanceMode)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HostPuzzle {
    let number: Int
    let grid: [[String]]
    let words: [String]
}

private struct HostGridPosition: Hashable {
    let row: Int
    let col: Int
}

private struct HostPuzzleProgress {
    let foundWords: Set<String>
    let solvedPositions: Set<HostGridPosition>

    static let empty = HostPuzzleProgress(foundWords: [], solvedPositions: [])
}

private struct HostGeneratedPuzzle {
    let grid: [[String]]
    let words: [String]
}

private struct HostWidgetProgressSnapshot {
    let grid: [[String]]
    let words: [String]
    let foundWords: Set<String>
    let solvedPositions: Set<HostGridPosition>
}

private enum HostWidgetProgressStore {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let stateKey = "puzzle_state_v3"

    static func loadSnapshot() -> HostWidgetProgressSnapshot? {
        guard let defaults = UserDefaults(suiteName: suite) else { return nil }
        guard let data = defaults.data(forKey: stateKey) else { return nil }
        guard let decoded = try? JSONDecoder().decode(SharedWidgetState.self, from: data) else { return nil }

        let normalizedGrid = decoded.grid.map { row in row.map { $0.uppercased() } }
        let normalizedWords = decoded.words.map { $0.uppercased() }
        let normalizedFoundWords = Set(decoded.foundWords.map { $0.uppercased() })
        let solvedPositions = Set(decoded.solvedPositions.map { HostGridPosition(row: $0.r, col: $0.c) })

        return HostWidgetProgressSnapshot(
            grid: normalizedGrid,
            words: normalizedWords,
            foundWords: normalizedFoundWords,
            solvedPositions: solvedPositions
        )
    }

    private struct SharedWidgetState: Decodable {
        let grid: [[String]]
        let words: [String]
        let foundWords: Set<String>
        let solvedPositions: Set<SharedWidgetPosition>

        private enum CodingKeys: String, CodingKey {
            case grid
            case words
            case foundWords
            case solvedPositions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            grid = try container.decodeIfPresent([[String]].self, forKey: .grid) ?? []
            words = try container.decodeIfPresent([String].self, forKey: .words) ?? []
            foundWords = try container.decodeIfPresent(Set<String>.self, forKey: .foundWords) ?? []
            solvedPositions = try container.decodeIfPresent(Set<SharedWidgetPosition>.self, forKey: .solvedPositions) ?? []
        }
    }

    private struct SharedWidgetPosition: Hashable, Decodable {
        let r: Int
        let c: Int
    }
}

private enum HostDifficultySettings {
    static let suite = "group.com.pedrocarrasco.miapp"
    static let gridSizeKey = "puzzle_grid_size_v1"
    static let minGridSize = 7
    static let maxGridSize = 12

    static func clampGridSize(_ value: Int) -> Int {
        min(max(value, minGridSize), maxGridSize)
    }

    static func gridSize() -> Int {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return minGridSize
        }
        let stored = defaults.integer(forKey: gridSizeKey)
        if stored == 0 {
            defaults.set(minGridSize, forKey: gridSizeKey)
            return minGridSize
        }
        let clamped = clampGridSize(stored)
        if clamped != stored {
            defaults.set(clamped, forKey: gridSizeKey)
        }
        return clamped
    }

    static func setGridSize(_ value: Int) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(clampGridSize(value), forKey: gridSizeKey)
    }
}

private enum HostAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

private enum HostAppearanceSettings {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let appearanceModeKey = "puzzle_theme_mode_v1"

    static func mode() -> HostAppearanceMode {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return .system
        }
        guard let raw = defaults.string(forKey: appearanceModeKey) else {
            return .system
        }
        return HostAppearanceMode(rawValue: raw) ?? .system
    }

    static func setMode(_ mode: HostAppearanceMode) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(mode.rawValue, forKey: appearanceModeKey)
    }
}

private enum HostPuzzleCalendar {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let installDateKey = "puzzle_installation_date_v1"
    private static let themes: [[String]] = [
        [
            "ARBOL", "TIERRA", "NUBE", "MAR", "SOL", "RIO", "FLOR", "LUNA", "MONTE", "VALLE",
            "BOSQUE", "RAMA", "ROCA", "PLAYA", "NIEVE", "VIENTO", "TRUENO", "FUEGO", "ARENA",
            "ISLA", "CIELO", "SELVA", "LLUVIA", "CAMINO", "MUSGO", "LAGO", "PRIMAVERA",
            "HORIZONTE", "ESTRELLA", "PLANETA"
        ],
        [
            "QUESO", "PAN", "MIEL", "LECHE", "UVA", "PERA", "CAFE", "TOMATE", "ACEITE", "SAL",
            "PASTA", "ARROZ", "PAPAYA", "MANGO", "BANANA", "NARANJA", "CEREZA", "SOPA",
            "TORTILLA", "GALLETA", "CHOCOLATE", "YOGUR", "MANZANA", "AVENA", "ENSALADA",
            "PIMIENTO", "LIMON", "COCO", "ALMENDRA", "ALBAHACA"
        ],
        [
            "TREN", "BUS", "CARRO", "PUERTA", "PLAYA", "LIBRO", "CINE", "PUENTE", "CALLE",
            "METRO", "AVION", "BARRIO", "PLAZA", "PARQUE", "TORRE", "MUSEO", "MAPA", "RUTA",
            "BICICLETA", "TRAFICO", "SEMAFORO", "ESTACION", "AUTOPISTA", "TAXI", "MOTOR",
            "VIAJE", "MOCHILA", "PASEO", "CIUDAD", "CARTEL"
        ]
    ]

    static func installationDate() -> Date {
        let calendar = Calendar.current
        let fallback = calendar.startOfDay(for: Date())
        guard let defaults = UserDefaults(suiteName: suite) else {
            return fallback
        }

        if let stored = defaults.object(forKey: installDateKey) as? Date {
            return calendar.startOfDay(for: stored)
        }

        defaults.set(fallback, forKey: installDateKey)
        return fallback
    }

    static func dayOffset(from start: Date, to target: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let targetDay = calendar.startOfDay(for: target)
        return max(calendar.dateComponents([.day], from: startDay, to: targetDay).day ?? 0, 0)
    }

    static func date(from start: Date, dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        return calendar.date(byAdding: .day, value: dayOffset, to: startDay) ?? startDay
    }

    static func puzzle(forDayOffset offset: Int, gridSize: Int) -> HostPuzzle {
        let normalized = normalizedPuzzleIndex(offset)
        let size = HostDifficultySettings.clampGridSize(gridSize)
        let seed = stableSeed(dayOffset: offset, gridSize: size)
        let words = selectWords(from: themes[normalized], gridSize: size, seed: seed)
        let generated = HostPuzzleGenerator.generate(gridSize: size, words: words, seed: seed)
        return HostPuzzle(number: normalized + 1, grid: generated.grid, words: generated.words)
    }

    private static func normalizedPuzzleIndex(_ offset: Int) -> Int {
        let count = max(themes.count, 1)
        let value = offset % count
        return value >= 0 ? value : value + count
    }

    private static func stableSeed(dayOffset: Int, gridSize: Int) -> UInt64 {
        let a = UInt64(bitPattern: Int64(dayOffset))
        let b = UInt64(gridSize) << 32
        return (a &* 0x9E3779B185EBCA87) ^ b ^ 0xC0DEC0FFEE12345F
    }

    private static func selectWords(from pool: [String], gridSize: Int, seed: UInt64) -> [String] {
        var filtered = pool
            .map { $0.uppercased() }
            .filter { $0.count >= 3 && $0.count <= gridSize }
        if filtered.isEmpty {
            filtered = ["SOL", "MAR", "RIO", "LUNA", "FLOR", "ROCA"]
        }

        var rng = HostPuzzleGenerator.SeededGenerator(seed: seed ^ 0xA11CE5EED)
        for index in stride(from: filtered.count - 1, through: 1, by: -1) {
            let swapAt = rng.int(upperBound: index + 1)
            if swapAt != index {
                filtered.swapAt(index, swapAt)
            }
        }

        let targetCount = min(filtered.count, max(7, 7 + (gridSize - 7) * 2))
        return Array(filtered.prefix(targetCount))
    }
}

private enum HostPuzzleGenerator {
    private static let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]
    private static let alphabet: [String] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }

    struct SeededGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0x1234ABCD5678EF90 : seed
        }

        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }

        mutating func int(upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(next() % UInt64(upperBound))
        }
    }

    static func generate(gridSize: Int, words: [String], seed: UInt64) -> HostGeneratedPuzzle {
        let size = HostDifficultySettings.clampGridSize(gridSize)
        let sortedWords = words
            .map { $0.uppercased() }
            .filter { !$0.isEmpty && $0.count <= size }
            .sorted { $0.count > $1.count }

        var fallback = makePuzzle(size: size, words: sortedWords, seed: seed, reduction: 0)
        if fallback.words.count >= 4 {
            return fallback
        }

        for reduction in [2, 4, 6] {
            let reduced = Array(sortedWords.prefix(max(4, sortedWords.count - reduction)))
            let attempt = makePuzzle(size: size, words: reduced, seed: seed, reduction: reduction)
            if attempt.words.count > fallback.words.count {
                fallback = attempt
            }
            if attempt.words.count >= max(4, reduced.count - 1) {
                return attempt
            }
        }

        return fallback
    }

    private static func makePuzzle(size: Int, words: [String], seed: UInt64, reduction: Int) -> HostGeneratedPuzzle {
        var rng = SeededGenerator(seed: seed ^ UInt64(reduction) ^ 0xFEEDBEEF15)
        var board = Array(repeating: Array(repeating: "", count: size), count: size)
        var placedWords: [String] = []

        for word in words {
            if place(word: word, on: &board, size: size, rng: &rng) {
                placedWords.append(word)
            }
        }

        for row in 0..<size {
            for col in 0..<size where board[row][col].isEmpty {
                board[row][col] = alphabet[rng.int(upperBound: alphabet.count)]
            }
        }

        return HostGeneratedPuzzle(grid: board, words: placedWords)
    }

    private static func place(word: String, on board: inout [[String]], size: Int, rng: inout SeededGenerator) -> Bool {
        let letters = word.map { String($0) }
        let count = letters.count
        guard count > 1 else { return false }

        for _ in 0..<300 {
            let direction = directions[rng.int(upperBound: directions.count)]
            let dr = direction.0
            let dc = direction.1

            let minRow = dr < 0 ? count - 1 : 0
            let maxRow = dr > 0 ? size - count : size - 1
            let minCol = dc < 0 ? count - 1 : 0
            let maxCol = dc > 0 ? size - count : size - 1

            if maxRow < minRow || maxCol < minCol {
                continue
            }

            let startRow = minRow + rng.int(upperBound: maxRow - minRow + 1)
            let startCol = minCol + rng.int(upperBound: maxCol - minCol + 1)

            var canPlace = true
            for index in 0..<count {
                let r = startRow + index * dr
                let c = startCol + index * dc
                let existing = board[r][c]
                if !existing.isEmpty && existing != letters[index] {
                    canPlace = false
                    break
                }
            }

            if !canPlace {
                continue
            }

            for index in 0..<count {
                let r = startRow + index * dr
                let c = startCol + index * dc
                board[r][c] = letters[index]
            }
            return true
        }

        return false
    }
}

private enum HostMaintenance {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let widgetKind = "WordSearchWidget"
    private static let resetRequestKey = "puzzle_reset_request_v1"

    static func resetCurrentPuzzle() {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: resetRequestKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func applyGridSize(_ gridSize: Int) {
        HostDifficultySettings.setGridSize(gridSize)
        resetCurrentPuzzle()
    }

    static func applyAppearance(_ mode: HostAppearanceMode) {
        HostAppearanceSettings.setMode(mode)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

#Preview {
    ContentView()
}
