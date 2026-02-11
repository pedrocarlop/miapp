/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Layout/SharedWordSearchBoardView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: SharedWordSearchBoardPosition,SharedWordSearchBoardFeedbackKind SharedWordSearchBoardFeedback,SharedWordSearchBoardOutline
 - Funciones clave en este archivo: cellFill,cellBorderColor cellBorderWidth,feedbackOverlay foundWordOverlay,activeSelectionStroke
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

import Foundation
import SwiftUI

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
        let boardShape = RoundedRectangle(cornerRadius: RadiusTokens.boardRadius, style: .continuous)

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
                                .font(TypographyTokens.boardLetter(size: max(10, cellSize * 0.45)))
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

            if activePositions.count > 1 {
                activeSelectionStroke(cellSize: cellSize)
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
        let capsuleHeight = cellSize * 0.76
        let lineWidth = max(1.0, min(2.1, cellSize * 0.07))

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
                    Capsule(style: .continuous)
                        .fill(ThemeGradients.brushWarm.opacity(0.44))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(palette.foundOutlineStroke.opacity(0.42), lineWidth: lineWidth)
                        )
                        .frame(width: capsuleWidth, height: capsuleHeight)
                        .rotationEffect(angle)
                        .position(centerPoint)
                }
            }
        }
    }

    private func activeSelectionStroke(cellSize: CGFloat) -> some View {
        let points = activePositions.map { center(for: $0, cellSize: cellSize) }
        let primaryWidth = max(1.1, min(2.0, cellSize * 0.075))
        let secondaryWidth = primaryWidth * 0.45
        let path = selectionPath(points: points)

        return path
            .stroke(
                palette.letterColor.opacity(0.58),
                style: StrokeStyle(
                    lineWidth: primaryWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .overlay {
                path.stroke(
                    palette.boardBackground.opacity(0.36),
                    style: StrokeStyle(
                        lineWidth: secondaryWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
    }

    private func selectionPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
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
                withAnimation(MotionTokens.smooth) {
                    animate = true
                }
            }
    }
}
