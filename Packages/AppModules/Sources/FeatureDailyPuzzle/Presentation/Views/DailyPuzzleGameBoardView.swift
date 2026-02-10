import SwiftUI
import Core
import DesignSystem

private typealias DailyPuzzleLoupeConfiguration = LoupeConfiguration
private typealias DailyPuzzleLoupeState = LoupeState

public enum DailyPuzzleBoardFeedbackKind: Sendable {
    case correct
    case incorrect
}

public struct DailyPuzzleBoardFeedback: Identifiable, Sendable {
    public let id: UUID
    public let kind: DailyPuzzleBoardFeedbackKind
    public let positions: [GridPosition]

    public init(id: UUID = UUID(), kind: DailyPuzzleBoardFeedbackKind, positions: [GridPosition]) {
        self.id = id
        self.kind = kind
        self.positions = positions
    }
}

public struct DailyPuzzleBoardCelebration: Identifiable, Sendable {
    public let id: UUID
    public let positions: [GridPosition]
    public let intensity: CelebrationIntensity
    public let popDuration: TimeInterval
    public let particleDuration: TimeInterval
    public let reduceMotion: Bool

    public init(
        id: UUID = UUID(),
        positions: [GridPosition],
        intensity: CelebrationIntensity,
        popDuration: TimeInterval,
        particleDuration: TimeInterval,
        reduceMotion: Bool
    ) {
        self.id = id
        self.positions = positions
        self.intensity = intensity
        self.popDuration = popDuration
        self.particleDuration = particleDuration
        self.reduceMotion = reduceMotion
    }
}

public struct DailyPuzzleGameBoardView: View {
    private static let defaultLoupeConfiguration = DailyPuzzleLoupeConfiguration(
        magnification: 1.42
    )

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let grid: [[String]]
    public let words: [String]
    public let foundWords: Set<String>
    public let solvedPositions: Set<GridPosition>
    public let activePositions: [GridPosition]
    public let feedback: DailyPuzzleBoardFeedback?
    public let celebrations: [DailyPuzzleBoardCelebration]
    public let sideLength: CGFloat
    public let onDragChanged: (GridPosition) -> Void
    public let onDragEnded: () -> Void
    public let isInteractive: Bool

    @State private var loupeState: DailyPuzzleLoupeState
    @State private var snapScale: CGFloat = 1
    @State private var snapTask: Task<Void, Never>?
    private let loupeConfiguration: DailyPuzzleLoupeConfiguration
    private let mappedSolvedWordOutlines: [SharedWordSearchBoardOutline]

    private struct WordOutline: Identifiable {
        let id: String
        let word: String
        let seed: Int
        let positions: [GridPosition]
    }

    private var rows: Int { grid.count }
    private var cols: Int { grid.first?.count ?? 0 }

    public init(
        grid: [[String]],
        words: [String],
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>,
        activePositions: [GridPosition],
        feedback: DailyPuzzleBoardFeedback?,
        celebrations: [DailyPuzzleBoardCelebration],
        sideLength: CGFloat,
        onDragChanged: @escaping (GridPosition) -> Void,
        onDragEnded: @escaping () -> Void,
        isInteractive: Bool = true
    ) {
        let loupeConfiguration = Self.defaultLoupeConfiguration
        self.grid = grid
        self.words = words
        self.foundWords = foundWords
        self.solvedPositions = solvedPositions
        self.activePositions = activePositions
        self.feedback = feedback
        self.celebrations = celebrations
        self.sideLength = sideLength
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.isInteractive = isInteractive
        self.loupeConfiguration = loupeConfiguration
        let outlines = Self.makeSolvedWordOutlines(
            words: words,
            foundWords: foundWords,
            grid: Core.PuzzleGrid(letters: grid),
            solvedPositions: solvedPositions
        )
        self.mappedSolvedWordOutlines = outlines.map { outline in
            SharedWordSearchBoardOutline(
                id: outline.id,
                word: outline.word,
                seed: outline.seed,
                positions: outline.positions.map { SharedWordSearchBoardPosition(row: $0.row, col: $0.col) }
            )
        }
        _loupeState = State(
            initialValue: DailyPuzzleLoupeState(configuration: loupeConfiguration)
        )
    }

    public var body: some View {
        let safeCols = max(cols, 1)
        let cellSize = sideLength / CGFloat(safeCols)
        let boardBounds = CGRect(origin: .zero, size: CGSize(width: sideLength, height: sideLength))
        let baseBoard = boardLayer(cellSize: cellSize)
            .frame(width: sideLength, height: sideLength)
            .contentShape(Rectangle())
            .scaleEffect(snapScale)
            .onChange(of: feedback?.id) { _ in
                triggerCorrectSnapIfNeeded()
            }
            .onDisappear {
                snapTask?.cancel()
                snapTask = nil
            }

        if isInteractive {
            baseBoard
                .overlay(alignment: .topLeading) {
                    DailyPuzzleLoupeView(
                        state: $loupeState,
                        configuration: loupeConfiguration,
                        boardSize: CGSize(width: sideLength, height: sideLength)
                    ) {
                        boardLayer(cellSize: cellSize)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            loupeState.update(
                                fingerLocation: value.location,
                                in: boardBounds,
                                configuration: loupeConfiguration
                            )
                            if let position = position(for: value.location, cellSize: cellSize) {
                                onDragChanged(position)
                            }
                        }
                        .onEnded { _ in
                            loupeState.hide()
                            onDragEnded()
                        }
                )
        } else {
            baseBoard
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func boardLayer(cellSize: CGFloat) -> some View {
        let mappedActive = activePositions.map { SharedWordSearchBoardPosition(row: $0.row, col: $0.col) }
        let mappedFeedback = feedback.map { value in
            SharedWordSearchBoardFeedback(
                id: value.id.uuidString,
                kind: value.kind == .correct ? .correct : .incorrect,
                positions: value.positions.map { SharedWordSearchBoardPosition(row: $0.row, col: $0.col) }
            )
        }
        let palette = SharedWordSearchBoardPalette(
            boardBackground: ColorTokens.surfacePaperGrid,
            boardCellBackground: ColorTokens.surfacePaperMuted,
            boardGridStroke: ColorTokens.boardGridStroke,
            boardOuterStroke: ColorTokens.boardOuterStroke,
            letterColor: ColorTokens.textPrimary,
            selectionFill: ColorTokens.accentCoral.opacity(0.15),
            foundOutlineStroke: ColorTokens.boardGridStroke,
            feedbackCorrect: ColorTokens.feedbackCorrect,
            feedbackIncorrect: ColorTokens.feedbackIncorrect,
            anchorBorder: ColorTokens.textSecondary.opacity(0.75)
        )

        ZStack {
            SharedWordSearchBoardView(
                grid: grid,
                sideLength: sideLength,
                activePositions: mappedActive,
                feedback: mappedFeedback,
                solvedWordOutlines: mappedSolvedWordOutlines,
                anchor: mappedActive.last,
                palette: palette
            )

            celebrationLayer(cellSize: cellSize)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func celebrationLayer(cellSize: CGFloat) -> some View {
        ZStack {
            ForEach(celebrations) { celebration in
                DailyPuzzleWordCelebrationSequenceView(
                    celebrationID: celebration.id,
                    grid: grid,
                    positions: celebration.positions,
                    cellSize: cellSize,
                    brushDuration: celebration.popDuration,
                    waveDuration: celebration.particleDuration,
                    intensity: celebration.intensity,
                    reduceMotion: celebration.reduceMotion
                )
            }
        }
    }

    private static func makeSolvedWordOutlines(
        words: [String],
        foundWords: Set<String>,
        grid: Core.PuzzleGrid,
        solvedPositions: Set<GridPosition>
    ) -> [WordOutline] {
        let normalizedFound = Set(foundWords.map { WordSearchNormalization.normalizedWord($0) })

        return words.enumerated().compactMap { index, rawWord in
            let normalized = WordSearchNormalization.normalizedWord(rawWord)
            guard normalizedFound.contains(normalized) else { return nil }
            guard let path = WordPathFinderService.bestPath(
                for: normalized,
                grid: grid,
                prioritizing: solvedPositions
            ) else { return nil }
            let signature = path.map { "\($0.row)-\($0.col)" }.joined(separator: "_")
            return WordOutline(
                id: "\(index)-\(normalized)-\(signature)",
                word: normalized,
                seed: index,
                positions: path
            )
        }
    }

    private func center(for position: GridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }

    private func position(for location: CGPoint, cellSize: CGFloat) -> GridPosition? {
        let row = Int(location.y / cellSize)
        let col = Int(location.x / cellSize)
        guard row >= 0, col >= 0, row < rows, col < cols else { return nil }
        return GridPosition(row: row, col: col)
    }

    private func triggerCorrectSnapIfNeeded() {
        guard feedback?.kind == .correct else { return }
        snapTask?.cancel()

        guard !reduceMotion else {
            snapScale = 1
            return
        }

        snapScale = 1
        snapTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.07)) {
                snapScale = 0.985
            }
            try? await Task.sleep(nanoseconds: 80_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.22, dampingFraction: 0.74)) {
                snapScale = 1
            }
        }
    }
}

private struct DailyPuzzleWordCelebrationSequenceView: View {
    let celebrationID: UUID
    let grid: [[String]]
    let positions: [GridPosition]
    let cellSize: CGFloat
    let brushDuration: TimeInterval
    let waveDuration: TimeInterval
    let intensity: CelebrationIntensity
    let reduceMotion: Bool

    @State private var brushProgress: CGFloat = 0
    @State private var activeLetterIndex: Int?
    @State private var sparkleVisible = false
    @State private var sequenceTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let first = positions.first, let last = positions.last {
                let startPoint = center(for: first, cellSize: cellSize)
                let endPoint = center(for: last, cellSize: cellSize)
                let dx = endPoint.x - startPoint.x
                let dy = endPoint.y - startPoint.y
                let angle = Angle(radians: atan2(dy, dx))
                let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
                let capsuleHeight = cellSize * 0.84
                let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)
                let revealedWidth = max(capsuleHeight * 0.36, capsuleWidth * brushProgress)

                ZStack {
                    DailyPuzzleBrushStrokeShape(seed: brushSeed)
                        .fill(ThemeGradients.brushWarmStrong.opacity(intensity.brushOpacity))
                        .overlay {
                            DailyPuzzleBrushStrokeShape(seed: brushSeed + 41)
                                .stroke(ColorTokens.accentAmberStrong.opacity(0.30), lineWidth: max(0.8, cellSize * 0.038))
                        }
                        .frame(width: capsuleWidth, height: capsuleHeight)
                        .mask {
                            Rectangle()
                                .frame(width: revealedWidth, height: capsuleHeight)
                                .frame(width: capsuleWidth, height: capsuleHeight, alignment: .leading)
                        }
                        .rotationEffect(angle)
                        .position(centerPoint)

                    ForEach(Array(positions.enumerated()), id: \.offset) { index, position in
                        Text(letter(at: position))
                            .font(TypographyTokens.boardLetter(size: max(10, cellSize * 0.45)))
                            .foregroundStyle(ColorTokens.inkPrimary)
                            .scaleEffect(letterScale(for: index))
                            .shadow(
                                color: ColorTokens.accentAmberStrong.opacity(activeLetterIndex == index ? 0.24 : 0),
                                radius: activeLetterIndex == index ? 3 : 0
                            )
                            .position(center(for: position, cellSize: cellSize))
                    }

                    if sparkleVisible {
                        DailyPuzzleSparkleGlyph(size: max(9, cellSize * 0.36))
                            .position(
                                CGPoint(
                                    x: endPoint.x + cellSize * 0.16,
                                    y: endPoint.y - cellSize * 0.21
                                )
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.45)))
                    }
                }
                .onAppear {
                    runSequence()
                }
                .onChange(of: celebrationID) { _ in
                    runSequence()
                }
                .onDisappear {
                    sequenceTask?.cancel()
                    sequenceTask = nil
                }
            }
        }
    }

    private var brushSeed: Int {
        positions.reduce(19) { result, position in
            (result &* 31) &+ (position.row &* 17) &+ (position.col &* 13)
        }
    }

    private func runSequence() {
        sequenceTask?.cancel()
        brushProgress = reduceMotion ? 1 : 0
        activeLetterIndex = nil
        sparkleVisible = false

        guard !positions.isEmpty else { return }

        let adjustedWaveDuration = waveDuration * intensity.waveDurationFactor
        let perLetterDelay = max(0.045, adjustedWaveDuration / Double(max(positions.count, 1)))
        let holdDuration = max(0.028, perLetterDelay * 0.62)

        sequenceTask = Task { @MainActor in
            if !reduceMotion {
                withAnimation(.easeOut(duration: brushDuration)) {
                    brushProgress = 1
                }
                try? await Task.sleep(
                    nanoseconds: UInt64(max(0.01, brushDuration - 0.015) * 1_000_000_000)
                )
            } else {
                brushProgress = 1
            }

            guard !Task.isCancelled else { return }

            for index in positions.indices {
                withAnimation(.spring(response: 0.20, dampingFraction: 0.60)) {
                    activeLetterIndex = index
                }
                try? await Task.sleep(nanoseconds: UInt64(holdDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.08)) {
                    if activeLetterIndex == index {
                        activeLetterIndex = nil
                    }
                }
                let coolDown = max(0.012, perLetterDelay - holdDuration)
                try? await Task.sleep(nanoseconds: UInt64(coolDown * 1_000_000_000))
                guard !Task.isCancelled else { return }
            }

            withAnimation(.easeOut(duration: reduceMotion ? 0.08 : 0.1)) {
                sparkleVisible = true
            }
            try? await Task.sleep(nanoseconds: 110_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                sparkleVisible = false
            }
        }
    }

    private func letterScale(for index: Int) -> CGFloat {
        guard activeLetterIndex == index else { return 1 }
        return reduceMotion ? 1.04 : intensity.popScale
    }

    private func center(for position: GridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }

    private func letter(at position: GridPosition) -> String {
        guard position.row >= 0,
              position.col >= 0,
              position.row < grid.count,
              position.col < grid[position.row].count else {
            return ""
        }
        return grid[position.row][position.col]
    }
}

private struct DailyPuzzleBrushStrokeShape: Shape {
    let seed: Int

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let sampleCount = max(10, Int(rect.width / max(6, rect.height * 0.36)))
        let halfHeight = rect.height * 0.5
        let seedA = CGFloat((seed % 23) + 1)
        let seedB = CGFloat((seed % 19) + 3)

        var topPoints: [CGPoint] = []
        var bottomPoints: [CGPoint] = []
        topPoints.reserveCapacity(sampleCount + 1)
        bottomPoints.reserveCapacity(sampleCount + 1)

        for index in 0...sampleCount {
            let t = CGFloat(index) / CGFloat(sampleCount)
            let x = rect.minX + rect.width * t
            let edgeTaper = 0.76 + 0.24 * sin(t * .pi)
            let noiseA = sin((t * 8.4) + seedA * 0.19) * 0.16
            let noiseB = cos((t * 13.6) + seedB * 0.23) * 0.11
            let jitter = (noiseA + noiseB) * rect.height

            topPoints.append(
                CGPoint(
                    x: x,
                    y: rect.midY - halfHeight * edgeTaper + jitter * 0.22
                )
            )
            bottomPoints.append(
                CGPoint(
                    x: x,
                    y: rect.midY + halfHeight * edgeTaper + jitter * 0.19
                )
            )
        }

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        for point in topPoints {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        for point in bottomPoints.reversed() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct DailyPuzzleSparkleGlyph: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .foregroundStyle(ColorTokens.accentAmberStrong)
            .shadow(color: ColorTokens.accentAmberStrong.opacity(0.30), radius: 4, x: 0, y: 0)
    }
}

private extension CelebrationIntensity {
    var popScale: CGFloat {
        switch self {
        case .low:
            return 1.11
        case .medium:
            return 1.16
        case .high:
            return 1.21
        }
    }

    var waveDurationFactor: Double {
        switch self {
        case .low:
            return 1.08
        case .medium:
            return 1
        case .high:
            return 0.9
        }
    }

    var brushOpacity: Double {
        switch self {
        case .low:
            return 0.58
        case .medium:
            return 0.66
        case .high:
            return 0.74
        }
    }
}

private struct DailyPuzzleLoupeView<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @Binding var state: DailyPuzzleLoupeState
    let configuration: DailyPuzzleLoupeConfiguration
    let boardSize: CGSize
    let content: Content

    init(
        state: Binding<DailyPuzzleLoupeState>,
        configuration: DailyPuzzleLoupeConfiguration,
        boardSize: CGSize,
        @ViewBuilder content: () -> Content
    ) {
        _state = state
        self.configuration = configuration
        self.boardSize = boardSize
        self.content = content()
    }

    var body: some View {
        if state.isVisible {
            let shape = RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
            let size = state.loupeSize
            let offsetX = -state.fingerLocation.x * state.magnification + size.width / 2
            let offsetY = -state.fingerLocation.y * state.magnification + size.height / 2

            ZStack {
                shape
                    .fill(
                        reduceTransparency
                        ? AnyShapeStyle(ColorTokens.surfaceTertiary)
                        : AnyShapeStyle(.thinMaterial)
                    )

                content
                    .frame(width: boardSize.width, height: boardSize.height, alignment: .topLeading)
                    .scaleEffect(state.magnification, anchor: .topLeading)
                    .offset(x: offsetX, y: offsetY)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .clipShape(shape)
            }
            .frame(width: size.width, height: size.height)
            .overlay(
                shape.stroke(
                    colorSchemeContrast == .increased
                    ? ColorTokens.textPrimary.opacity(0.45)
                    : ColorTokens.textSecondary.opacity(0.22),
                    lineWidth: configuration.borderWidth
                )
            )
            .position(state.loupeScreenPosition)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}

