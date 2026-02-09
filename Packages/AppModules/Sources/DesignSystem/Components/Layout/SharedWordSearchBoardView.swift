import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct SharedWordSearchBoardPosition: Hashable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

public enum SharedWordSearchBoardFeedbackKind {
    case correct
    case incorrect
}

public struct SharedWordSearchBoardFeedback {
    public let id: String
    public let kind: SharedWordSearchBoardFeedbackKind
    public let positions: [SharedWordSearchBoardPosition]

    public init(
        id: String = UUID().uuidString,
        kind: SharedWordSearchBoardFeedbackKind,
        positions: [SharedWordSearchBoardPosition]
    ) {
        self.id = id
        self.kind = kind
        self.positions = positions
    }
}

public struct SharedWordSearchBoardOutline: Identifiable {
    public let id: String
    public let word: String
    public let seed: Int
    public let positions: [SharedWordSearchBoardPosition]

    public init(id: String, word: String, seed: Int, positions: [SharedWordSearchBoardPosition]) {
        self.id = id
        self.word = word
        self.seed = seed
        self.positions = positions
    }
}

public struct SharedWordSearchBoardPalette {
    public let boardBackground: Color
    public let boardCellBackground: Color
    public let boardGridStroke: Color
    public let boardOuterStroke: Color
    public let letterColor: Color
    public let selectionFill: Color
    public let foundOutlineStroke: Color
    public let feedbackCorrect: Color
    public let feedbackIncorrect: Color
    public let anchorBorder: Color

    public init(
        boardBackground: Color,
        boardCellBackground: Color,
        boardGridStroke: Color,
        boardOuterStroke: Color,
        letterColor: Color,
        selectionFill: Color,
        foundOutlineStroke: Color,
        feedbackCorrect: Color,
        feedbackIncorrect: Color,
        anchorBorder: Color
    ) {
        self.boardBackground = boardBackground
        self.boardCellBackground = boardCellBackground
        self.boardGridStroke = boardGridStroke
        self.boardOuterStroke = boardOuterStroke
        self.letterColor = letterColor
        self.selectionFill = selectionFill
        self.foundOutlineStroke = foundOutlineStroke
        self.feedbackCorrect = feedbackCorrect
        self.feedbackIncorrect = feedbackIncorrect
        self.anchorBorder = anchorBorder
    }
}

public struct SharedWordSearchBoardView: View {
    public let grid: [[String]]
    public let sideLength: CGFloat
    public let activePositions: [SharedWordSearchBoardPosition]
    public let feedback: SharedWordSearchBoardFeedback?
    public let solvedWordOutlines: [SharedWordSearchBoardOutline]
    public let anchor: SharedWordSearchBoardPosition?
    public let palette: SharedWordSearchBoardPalette

    private var rows: Int { grid.count }
    private var cols: Int { grid.first?.count ?? 0 }

    public init(
        grid: [[String]],
        sideLength: CGFloat,
        activePositions: [SharedWordSearchBoardPosition],
        feedback: SharedWordSearchBoardFeedback?,
        solvedWordOutlines: [SharedWordSearchBoardOutline],
        anchor: SharedWordSearchBoardPosition?,
        palette: SharedWordSearchBoardPalette
    ) {
        self.grid = grid
        self.sideLength = sideLength
        self.activePositions = activePositions
        self.feedback = feedback
        self.solvedWordOutlines = solvedWordOutlines
        self.anchor = anchor
        self.palette = palette
    }

    public var body: some View {
        let safeRows = max(rows, 1)
        let safeCols = max(cols, 1)
        let cellSize = sideLength / CGFloat(safeCols)
        let boardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        ZStack {
            boardShape
                .fill(palette.boardBackground)

            VStack(spacing: 0) {
                ForEach(0..<safeRows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<safeCols, id: \.self) { col in
                            let position = SharedWordSearchBoardPosition(row: row, col: col)
                            let letter = row < rows && col < cols ? grid[row][col] : ""

                            Text(letter)
                                .font(.system(size: max(10, cellSize * 0.45), weight: .semibold, design: .monospaced))
                                .foregroundStyle(palette.letterColor)
                                .frame(width: cellSize, height: cellSize)
                                .background(cellFill(for: position))
                                .overlay(
                                    Rectangle()
                                        .stroke(cellBorderColor(for: position), lineWidth: cellBorderWidth(for: position))
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(palette.boardGridStroke, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .clipShape(boardShape)

            foundWordOverlay(cellSize: cellSize)
                .allowsHitTesting(false)

            if activePositions.count > 1,
               let first = activePositions.first,
               let last = activePositions.last {
                selectionCapsule(from: first, to: last, cellSize: cellSize)
                    .allowsHitTesting(false)
            }

            feedbackOverlay(cellSize: cellSize)
                .allowsHitTesting(false)
        }
        .compositingGroup()
        .clipShape(boardShape)
        .overlay(
            boardShape
                .stroke(palette.boardOuterStroke, lineWidth: 1)
        )
        .frame(width: sideLength, height: sideLength)
    }

    private var activeSet: Set<SharedWordSearchBoardPosition> {
        Set(activePositions)
    }

    private var feedbackSet: Set<SharedWordSearchBoardPosition> {
        Set(feedback?.positions ?? [])
    }

    private func cellFill(for position: SharedWordSearchBoardPosition) -> Color {
        if activeSet.contains(position) {
            return palette.selectionFill
        }
        return palette.boardCellBackground
    }

    private func cellBorderColor(for position: SharedWordSearchBoardPosition) -> Color {
        guard let anchor, anchor == position, !feedbackSet.contains(position) else {
            return .clear
        }
        return palette.anchorBorder
    }

    private func cellBorderWidth(for position: SharedWordSearchBoardPosition) -> CGFloat {
        guard let anchor, anchor == position, !feedbackSet.contains(position) else {
            return 0
        }
        return 1.8
    }

    @ViewBuilder
    private func feedbackOverlay(cellSize: CGFloat) -> some View {
        if let feedback,
           let first = feedback.positions.first,
           let last = feedback.positions.last {
            let capsuleHeight = cellSize * 0.82
            let lineWidth = max(1.8, min(3.6, cellSize * 0.12))
            let color = feedback.kind == .correct ? palette.feedbackCorrect : palette.feedbackIncorrect

            SharedWordSearchStretchingCapsule(
                start: center(for: first, cellSize: cellSize),
                end: center(for: last, cellSize: cellSize),
                capsuleHeight: capsuleHeight,
                lineWidth: lineWidth,
                color: color
            )
            .id(feedback.id)
        }
    }

    private func foundWordOverlay(cellSize: CGFloat) -> some View {
        let capsuleHeight = cellSize * 0.82
        let lineWidth = max(1.5, min(3.0, cellSize * 0.10))

        return ZStack {
            ForEach(solvedWordOutlines) { outline in
                if let first = outline.positions.first,
                   let last = outline.positions.last {
                    let startPoint = center(for: first, cellSize: cellSize)
                    let endPoint = center(for: last, cellSize: cellSize)
                    let dx = endPoint.x - startPoint.x
                    let dy = endPoint.y - startPoint.y
                    let angle = Angle(radians: atan2(dy, dx))
                    let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
                    let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)
                    let gradient = SharedWordGradientPalette.gradient(for: outline.word, seed: outline.seed)

                    Capsule(style: .continuous)
                        .fill(gradient.opacity(0.45))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(palette.foundOutlineStroke, lineWidth: lineWidth)
                        )
                        .frame(width: capsuleWidth, height: capsuleHeight)
                        .rotationEffect(angle)
                        .position(centerPoint)
                }
            }
        }
    }

    private func selectionCapsule(
        from start: SharedWordSearchBoardPosition,
        to end: SharedWordSearchBoardPosition,
        cellSize: CGFloat
    ) -> some View {
        let startPoint = center(for: start, cellSize: cellSize)
        let endPoint = center(for: end, cellSize: cellSize)
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let angle = Angle(radians: atan2(dy, dx))
        let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
        let capsuleHeight = cellSize * 0.82
        let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

        return Capsule(style: .continuous)
            .fill(palette.selectionFill)
            .frame(width: capsuleWidth, height: capsuleHeight)
            .rotationEffect(angle)
            .position(centerPoint)
    }

    private func center(for position: SharedWordSearchBoardPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }
}

private struct SharedWordSearchStretchingCapsule: View {
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

private enum SharedWordGradientPalette {
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
