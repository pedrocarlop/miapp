/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleGameBoardView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleBoardFeedbackKind,DailyPuzzleBoardFeedback DailyPuzzleBoardCelebration,DailyPuzzleGameBoardView
 - Funciones clave en este archivo: boardLayer,celebrationLayer position,triggerCorrectSnapIfNeeded
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
        size: CGSize(width: 180, height: 56),
        magnification: 1,
        offset: CGSize(width: 0, height: -72),
        edgePadding: 10
    )

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let grid: [[String]]
    public let words: [String]
    public let foundWords: Set<String>
    public let solvedPositions: Set<GridPosition>
    public let activePositions: [GridPosition]
    public let selectionText: String
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
        selectionText: String,
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
        self.selectionText = selectionText
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
                        boardSize: CGSize(width: sideLength, height: sideLength),
                        selectedText: selectionText,
                        shouldAvoidTopRowFingerOverlap: activePositions.contains { $0.row == 0 }
                    )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if let position = position(for: value.location, cellSize: cellSize) {
                                onDragChanged(position)
                            }
                            loupeState.update(
                                fingerLocation: value.location,
                                in: boardBounds,
                                configuration: loupeConfiguration
                            )
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

        ZStack {
            SharedWordSearchBoardView(
                grid: grid,
                sideLength: sideLength,
                activePositions: mappedActive,
                feedback: mappedFeedback,
                solvedWordOutlines: mappedSolvedWordOutlines,
                anchor: mappedActive.last,
                palette: WordSearchBoardStylePreset.gameBoard
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
