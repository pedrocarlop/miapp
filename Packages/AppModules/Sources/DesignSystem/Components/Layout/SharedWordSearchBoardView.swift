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
    public let letterCounterRotationDegrees: Double

    private var rows: Int { grid.count }
    private var cols: Int { grid.first?.count ?? 0 }

    public init(
        grid: [[String]],
        sideLength: CGFloat,
        activePositions: [SharedWordSearchBoardPosition],
        feedback: SharedWordSearchBoardFeedback?,
        solvedWordOutlines: [SharedWordSearchBoardOutline],
        anchor: SharedWordSearchBoardPosition?,
        palette: SharedWordSearchBoardPalette,
        letterCounterRotationDegrees: Double = 0
    ) {
        self.grid = grid
        self.sideLength = sideLength
        self.activePositions = activePositions
        self.feedback = feedback
        self.solvedWordOutlines = solvedWordOutlines
        self.anchor = anchor
        self.palette = palette
        self.letterCounterRotationDegrees = letterCounterRotationDegrees
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
                            let letter = row < rows && col < cols ? grid[row][col] : ""

                            Text(letter)
                                .font(TypographyTokens.boardLetter(size: max(10, cellSize * 0.45)))
                                .foregroundStyle(palette.letterColor)
                                .rotationEffect(.degrees(letterCounterRotationDegrees))
                                .frame(width: cellSize, height: cellSize)
                                .background(palette.boardCellBackground)
                                .overlay(
                                    Rectangle()
                                        .dsInnerStroke(palette.boardGridStroke, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .clipShape(boardShape)

            foundWordOverlay(cellSize: cellSize)
                .allowsHitTesting(false)

            selectionOverlay(cellSize: cellSize)
                .allowsHitTesting(false)
        }
        .compositingGroup()
        .clipShape(boardShape)
        .overlay(
            boardShape
                .dsInnerStroke(palette.boardOuterStroke, lineWidth: 1)
        )
        .frame(width: sideLength, height: sideLength)
    }

    @ViewBuilder
    private func selectionOverlay(cellSize: CGFloat) -> some View {
        let capsuleHeight = cellSize * 0.82
        let lineWidth = max(1.8, min(3.6, cellSize * 0.12))
        let baseColor = palette.letterColor.opacity(0.58)

        if let feedback,
           let first = feedback.positions.first,
           let last = feedback.positions.last {
            let feedbackColor = feedback.kind == .correct ? palette.feedbackCorrect : palette.feedbackIncorrect
            SharedWordSearchSelectionCapsule(
                start: center(for: first, cellSize: cellSize),
                end: center(for: last, cellSize: cellSize),
                capsuleHeight: capsuleHeight,
                lineWidth: lineWidth,
                baseColor: baseColor,
                revealColor: feedbackColor,
                revealID: feedback.id
            )
        } else if let first = activePositions.first,
                  let last = activePositions.last {
            SharedWordSearchSelectionCapsule(
                start: center(for: first, cellSize: cellSize),
                end: center(for: last, cellSize: cellSize),
                capsuleHeight: capsuleHeight,
                lineWidth: lineWidth,
                baseColor: baseColor,
                revealColor: nil,
                revealID: nil
            )
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
                                .dsInnerStroke(palette.foundOutlineStroke.opacity(0.42), lineWidth: lineWidth)
                        )
                        .frame(width: capsuleWidth, height: capsuleHeight)
                        .rotationEffect(angle)
                        .position(centerPoint)
                }
            }
        }
    }

    private func center(for position: SharedWordSearchBoardPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }
}

private struct SharedWordSearchSelectionCapsule: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let start: CGPoint
    let end: CGPoint
    let capsuleHeight: CGFloat
    let lineWidth: CGFloat
    let baseColor: Color
    let revealColor: Color?
    let revealID: String?

    @State private var revealProgress: CGFloat = 0

    var body: some View {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = Angle(radians: atan2(dy, dx))
        let centerPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)
        let revealWidth = capsuleWidth * revealProgress
        let revealMaskWidth = min(capsuleWidth + lineWidth, max(0, revealWidth + lineWidth))

        return ZStack(alignment: .leading) {
            if revealColor == nil {
                Capsule(style: .continuous)
                    .strokeBorder(baseColor, lineWidth: lineWidth, antialiased: true)
            }

            if let revealColor {
                Capsule(style: .continuous)
                    .strokeBorder(revealColor, lineWidth: lineWidth, antialiased: true)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: revealMaskWidth)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
            }
        }
            .frame(width: capsuleWidth, height: capsuleHeight)
            .rotationEffect(angle)
            .position(centerPoint)
            .onAppear {
                resetRevealState(animated: true)
            }
            .onChange(of: revealID) { _ in
                resetRevealState(animated: true)
            }
            .onChange(of: revealColor != nil) { _ in
                resetRevealState(animated: true)
            }
    }

    private func resetRevealState(animated: Bool) {
        guard revealColor != nil else {
            revealProgress = 0
            return
        }

        if reduceMotion {
            revealProgress = 1
            return
        }

        revealProgress = 0
        if animated {
            withAnimation(.easeOut(duration: MotionTokens.fastDuration)) {
                revealProgress = 1
            }
        } else {
            revealProgress = 1
        }
    }
}
