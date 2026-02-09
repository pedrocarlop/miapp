import SwiftUI
import Core
import DesignSystem
#if canImport(UIKit)
import UIKit
#endif

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
    public let showsParticles: Bool
    public let popDuration: TimeInterval
    public let particleDuration: TimeInterval
    public let reduceMotion: Bool

    public init(
        id: UUID = UUID(),
        positions: [GridPosition],
        intensity: CelebrationIntensity,
        showsParticles: Bool,
        popDuration: TimeInterval,
        particleDuration: TimeInterval,
        reduceMotion: Bool
    ) {
        self.id = id
        self.positions = positions
        self.intensity = intensity
        self.showsParticles = showsParticles
        self.popDuration = popDuration
        self.particleDuration = particleDuration
        self.reduceMotion = reduceMotion
    }
}

public struct DailyPuzzleGameBoardView: View {
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

    @State private var loupeState = DailyPuzzleLoupeState(configuration: .default)
    private let loupeConfiguration = DailyPuzzleLoupeConfiguration.default

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
    }

    public var body: some View {
        let safeCols = max(cols, 1)
        let cellSize = sideLength / CGFloat(safeCols)
        let boardBounds = CGRect(origin: .zero, size: CGSize(width: sideLength, height: sideLength))
        let baseBoard = boardLayer(cellSize: cellSize)
            .frame(width: sideLength, height: sideLength)
            .contentShape(Rectangle())

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
        let mappedOutlines = solvedWordOutlines.map { outline in
            SharedWordSearchBoardOutline(
                id: outline.id,
                word: outline.word,
                seed: outline.seed,
                positions: outline.positions.map { SharedWordSearchBoardPosition(row: $0.row, col: $0.col) }
            )
        }
        let palette = SharedWordSearchBoardPalette(
            boardBackground: ColorTokens.chipNeutralFill,
            boardCellBackground: ColorTokens.chipNeutralFill,
            boardGridStroke: ColorTokens.boardGridStroke,
            boardOuterStroke: ColorTokens.boardOuterStroke,
            letterColor: ColorTokens.textPrimary,
            selectionFill: ColorTokens.selectionFill,
            foundOutlineStroke: ColorTokens.textPrimary.opacity(0.82),
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
                solvedWordOutlines: mappedOutlines,
                anchor: nil,
                palette: palette
            )

            celebrationLayer(cellSize: cellSize)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func celebrationLayer(cellSize: CGFloat) -> some View {
        let boardSize = cellSize * CGFloat(max(cols, 1))

        ZStack {
            ForEach(celebrations) { celebration in
                DailyPuzzleCelebrationGlowCapsule(
                    positions: celebration.positions,
                    cellSize: cellSize,
                    duration: celebration.popDuration,
                    reduceMotion: celebration.reduceMotion
                )
            }

            #if canImport(UIKit)
            ForEach(celebrations.filter { $0.showsParticles }) { celebration in
                let trailPoints = celebration.positions.map { center(for: $0, cellSize: cellSize) }
                DailyPuzzleParticleBurstView(
                    burstID: celebration.id,
                    trailPoints: trailPoints,
                    intensity: celebration.intensity,
                    duration: celebration.particleDuration,
                    reduceMotion: celebration.reduceMotion
                )
                .frame(width: boardSize, height: boardSize)
            }
            #endif
        }
    }

    private var solvedWordOutlines: [WordOutline] {
        let normalizedFound = Set(foundWords.map { WordSearchNormalization.normalizedWord($0) })

        return words.enumerated().compactMap { index, rawWord in
            let normalized = WordSearchNormalization.normalizedWord(rawWord)
            guard normalizedFound.contains(normalized) else { return nil }
            guard let path = bestPath(for: normalized) else { return nil }
            let signature = path.map { "\($0.row)-\($0.col)" }.joined(separator: "_")
            return WordOutline(
                id: "\(index)-\(normalized)-\(signature)",
                word: normalized,
                seed: index,
                positions: path
            )
        }
    }

    private func bestPath(for word: String) -> [GridPosition]? {
        WordPathFinderService.bestPath(
            for: word,
            grid: Grid(letters: grid),
            prioritizing: solvedPositions
        )
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
}

private struct DailyPuzzleCelebrationGlowCapsule: View {
    let positions: [GridPosition]
    let cellSize: CGFloat
    let duration: TimeInterval
    let reduceMotion: Bool

    @State private var animate = false

    var body: some View {
        let capsuleHeight = cellSize * 0.82
        let lineWidth = max(1.8, min(3.8, cellSize * 0.12))

        guard let first = positions.first, let last = positions.last else {
            return AnyView(EmptyView())
        }

        let startPoint = center(for: first, cellSize: cellSize)
        let endPoint = center(for: last, cellSize: cellSize)
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let angle = Angle(radians: atan2(dy, dx))
        let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
        let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

        let view = Capsule(style: .continuous)
            .stroke(ColorTokens.success.opacity(0.85), lineWidth: lineWidth)
            .shadow(color: ColorTokens.success.opacity(animate ? 0.55 : 0), radius: animate ? 10 : 2)
            .frame(width: capsuleWidth, height: capsuleHeight)
            .scaleEffect(reduceMotion ? 1.0 : (animate ? 1.03 : 0.92))
            .opacity(animate ? 1 : 0)
            .rotationEffect(angle)
            .position(centerPoint)
            .onAppear {
                if reduceMotion {
                    animate = true
                } else {
                    withAnimation(.easeOut(duration: duration)) {
                        animate = true
                    }
                }
            }

        return AnyView(view)
    }

    private func center(for position: GridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }
}

#if canImport(UIKit)
private struct DailyPuzzleParticleBurstView: UIViewRepresentable {
    let burstID: UUID
    let trailPoints: [CGPoint]
    let intensity: CelebrationIntensity
    let duration: TimeInterval
    let reduceMotion: Bool

    func makeUIView(context: Context) -> DailyPuzzleParticleBurstUIView {
        DailyPuzzleParticleBurstUIView()
    }

    func updateUIView(_ uiView: DailyPuzzleParticleBurstUIView, context: Context) {
        uiView.burst(
            id: burstID,
            trailPoints: trailPoints,
            intensity: intensity,
            duration: duration,
            reduceMotion: reduceMotion
        )
    }
}

private final class DailyPuzzleParticleBurstUIView: UIView {
    private let emitter = CAEmitterLayer()
    private var lastBurstID: UUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        emitter.emitterShape = .circle
        emitter.renderMode = .additive
        layer.addSublayer(emitter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.frame = bounds
    }

    func burst(
        id: UUID,
        trailPoints: [CGPoint],
        intensity: CelebrationIntensity,
        duration: TimeInterval,
        reduceMotion: Bool
    ) {
        guard lastBurstID != id else { return }
        lastBurstID = id

        guard !reduceMotion else {
            emitter.birthRate = 0
            return
        }

        let points = trailPoints.isEmpty ? [CGPoint(x: bounds.midX, y: bounds.midY)] : trailPoints
        let startPoint = points.first ?? CGPoint(x: bounds.midX, y: bounds.midY)
        let endPoint = points.last ?? startPoint

        emitter.removeAnimation(forKey: "trail")
        emitter.emitterPosition = startPoint
        emitter.emitterSize = CGSize(width: 8, height: 8)
        let now = CACurrentMediaTime()
        emitter.beginTime = now
        emitter.emitterCells = DailyPuzzleParticleFactory.wordCells(intensity: intensity, duration: duration)
        emitter.birthRate = 1

        if points.count > 1 {
            let path = CGMutablePath()
            path.addLines(between: points)

            var totalDistance: CGFloat = 0
            let segmentCount = points.count - 1
            for index in 1..<points.count {
                let dx = points[index].x - points[index - 1].x
                let dy = points[index].y - points[index - 1].y
                totalDistance += hypot(dx, dy)
            }

            let distanceTravel = Double(totalDistance / 420)
            let stepTravel = Double(segmentCount) * 0.045
            let travelUpperBound = max(0.34, duration + 0.04)
            let travel = min(travelUpperBound, max(0.22, max(distanceTravel, stepTravel)))
            let positionAnimation = CAKeyframeAnimation(keyPath: "emitterPosition")
            positionAnimation.path = path
            positionAnimation.beginTime = now
            positionAnimation.duration = travel
            positionAnimation.calculationMode = .paced
            emitter.add(positionAnimation, forKey: "trail")
            emitter.emitterPosition = endPoint

            DispatchQueue.main.asyncAfter(deadline: .now() + travel + 0.03) { [weak self] in
                self?.emitter.birthRate = 0
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + min(0.18, duration * 0.45)) { [weak self] in
            self?.emitter.birthRate = 0
        }
    }
}

private enum DailyPuzzleParticleFactory {
    private static let sparkleImages: [CGImage] = [
        makeSparkImage(color: UIColor.systemYellow),
        makeSparkImage(color: UIColor.systemTeal),
        makeSparkImage(color: UIColor.systemBlue),
        makeSparkImage(color: UIColor.systemOrange)
    ]

    static func wordCells(intensity: CelebrationIntensity, duration: TimeInterval) -> [CAEmitterCell] {
        let birthRate = intensity.particleBirthRate
        let velocity = intensity.particleVelocity * 1.35
        let scale = intensity.particleScale

        return sparkleImages.map { image in
            let cell = CAEmitterCell()
            cell.contents = image
            cell.birthRate = birthRate
            cell.lifetime = Float(max(0.18, duration * 0.82))
            cell.lifetimeRange = Float(duration * 0.18)
            cell.velocity = velocity
            cell.velocityRange = velocity * 0.55
            cell.emissionRange = .pi * 2
            cell.scale = scale * 0.82
            cell.scaleRange = scale * 0.28
            cell.alphaSpeed = -2.4
            cell.spin = 1.6
            cell.spinRange = 2.6
            cell.yAcceleration = 20
            cell.xAcceleration = 8
            return cell
        }
    }

    private static func makeSparkImage(color: UIColor) -> CGImage {
        let size = CGSize(width: 14, height: 4)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let sparkRect = rect.insetBy(dx: 1.2, dy: 1.2)
            let sparkPath = UIBezierPath(roundedRect: sparkRect, cornerRadius: sparkRect.height * 0.5)

            cg.setShadow(offset: .zero, blur: 2.8, color: color.withAlphaComponent(0.65).cgColor)
            cg.setFillColor(color.cgColor)
            cg.addPath(sparkPath.cgPath)
            cg.fillPath()

            cg.setShadow(offset: .zero, blur: 0, color: nil)
            let coreRect = sparkRect.insetBy(dx: sparkRect.width * 0.30, dy: sparkRect.height * 0.18)
            let corePath = UIBezierPath(roundedRect: coreRect, cornerRadius: coreRect.height * 0.5)
            cg.setFillColor(UIColor.white.withAlphaComponent(0.68).cgColor)
            cg.addPath(corePath.cgPath)
            cg.fillPath()
        }
        if let cgImage = image.cgImage {
            return cgImage
        }
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }.cgImage!
    }
}

private extension CelebrationIntensity {
    var particleVelocity: CGFloat {
        switch self {
        case .low:
            return 90
        case .medium:
            return 110
        case .high:
            return 130
        }
    }

    var particleScale: CGFloat {
        switch self {
        case .low:
            return 0.45
        case .medium:
            return 0.55
        case .high:
            return 0.65
        }
    }
}
#endif

private struct DailyPuzzleLoupeConfiguration {
    var size: CGSize
    var magnification: CGFloat
    var offset: CGSize
    var edgePadding: CGFloat
    var cornerRadius: CGFloat
    var borderWidth: CGFloat
    var smoothing: CGFloat

    init(
        size: CGSize = CGSize(width: 110, height: 110),
        magnification: CGFloat = 1.7,
        offset: CGSize = CGSize(width: 0, height: -70),
        edgePadding: CGFloat = 8,
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat = 1.2,
        smoothing: CGFloat = 0.22
    ) {
        self.size = size
        self.magnification = magnification
        self.offset = offset
        self.edgePadding = edgePadding
        self.cornerRadius = cornerRadius ?? min(size.width, size.height) * 0.5
        self.borderWidth = borderWidth
        self.smoothing = smoothing
    }

    static let `default` = DailyPuzzleLoupeConfiguration()
}

private struct DailyPuzzleLoupeState {
    var isVisible: Bool = false
    var fingerLocation: CGPoint = .zero
    var loupeScreenPosition: CGPoint = .zero
    var magnification: CGFloat
    var loupeSize: CGSize

    init(configuration: DailyPuzzleLoupeConfiguration = .default) {
        magnification = configuration.magnification
        loupeSize = configuration.size
    }

    mutating func update(
        fingerLocation: CGPoint,
        in bounds: CGRect,
        configuration: DailyPuzzleLoupeConfiguration
    ) {
        magnification = configuration.magnification
        loupeSize = configuration.size

        let clampedFinger = fingerLocation.clamped(to: bounds)
        self.fingerLocation = clampedFinger

        let target = DailyPuzzleLoupeState.clampedLoupePosition(
            fingerLocation: fingerLocation,
            bounds: bounds,
            size: configuration.size,
            offset: configuration.offset,
            edgePadding: configuration.edgePadding
        )

        if !isVisible {
            isVisible = true
            loupeScreenPosition = target
        } else {
            loupeScreenPosition = loupeScreenPosition.lerped(
                to: target,
                alpha: configuration.smoothing
            )
        }
    }

    mutating func hide() {
        isVisible = false
    }

    private static func clampedLoupePosition(
        fingerLocation: CGPoint,
        bounds: CGRect,
        size: CGSize,
        offset: CGSize,
        edgePadding: CGFloat
    ) -> CGPoint {
        let raw = CGPoint(
            x: fingerLocation.x + offset.width,
            y: fingerLocation.y + offset.height
        )
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let minX = bounds.minX + halfWidth + edgePadding
        let maxX = bounds.maxX - halfWidth - edgePadding
        let minY = bounds.minY + halfHeight + edgePadding
        let maxY = bounds.maxY - halfHeight - edgePadding

        return CGPoint(
            x: min(max(raw.x, minX), maxX),
            y: min(max(raw.y, minY), maxY)
        )
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

private extension CGPoint {
    func lerped(to target: CGPoint, alpha: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (target.x - x) * alpha,
            y: y + (target.y - y) * alpha
        )
    }

    func clamped(to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(x, rect.minX), rect.maxX),
            y: min(max(y, rect.minY), rect.maxY)
        )
    }
}
