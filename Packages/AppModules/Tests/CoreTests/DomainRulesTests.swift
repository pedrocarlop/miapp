/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/CoreTests/DomainRulesTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: DomainRulesTests
 - Funciones clave en este archivo: makePuzzle,testHorizontalSelectionValidationSuccess testVerticalSelectionValidationSuccess,testDiagonalSelectionValidationSuccess testNonLinearSelectionRejected,testReverseWordMatchingAccepted
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

import XCTest
@testable import Core

final class DomainRulesTests: XCTestCase {
    private func makePuzzle() -> Puzzle {
        let grid = PuzzleGrid(letters: [
            ["C", "A", "T", "X", "X"],
            ["X", "O", "O", "X", "X"],
            ["X", "X", "G", "X", "X"],
            ["D", "O", "G", "X", "X"],
            ["X", "X", "X", "X", "X"]
        ])

        let words = ["CAT", "DOG", "COG", "TOG"].map(Word.init(text:))
        return Puzzle(number: 1, dayKey: DayKey(offset: 0), grid: grid, words: words)
    }

    func testHorizontalSelectionValidationSuccess() {
        let puzzle = makePuzzle()
        let selection = Selection(positions: [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2)
        ])

        let result = ValidateSelectionUseCase().execute(selection: selection, puzzle: puzzle, foundWords: [])

        XCTAssertEqual(result.matchedWord, "CAT")
    }

    func testVerticalSelectionValidationSuccess() {
        let puzzle = makePuzzle()
        let selection = Selection(positions: [
            GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 2),
            GridPosition(row: 2, col: 2)
        ])

        let result = ValidateSelectionUseCase().execute(selection: selection, puzzle: puzzle, foundWords: [])

        XCTAssertEqual(result.matchedWord, "TOG")
    }

    func testDiagonalSelectionValidationSuccess() {
        let puzzle = makePuzzle()
        let selection = Selection(positions: [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 1, col: 1),
            GridPosition(row: 2, col: 2)
        ])

        let result = ValidateSelectionUseCase().execute(selection: selection, puzzle: puzzle, foundWords: [])

        XCTAssertEqual(result.matchedWord, "COG")
    }

    func testNonLinearSelectionRejected() {
        let puzzle = makePuzzle()
        let selection = Selection(positions: [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 1, col: 2),
            GridPosition(row: 2, col: 2)
        ])

        let result = ValidateSelectionUseCase().execute(selection: selection, puzzle: puzzle, foundWords: [])

        XCTAssertNil(result.matchedWord)
    }

    func testReverseWordMatchingAccepted() {
        let puzzle = makePuzzle()
        let selection = Selection(positions: [
            GridPosition(row: 0, col: 2),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 0)
        ])

        let result = ValidateSelectionUseCase().execute(selection: selection, puzzle: puzzle, foundWords: [])

        XCTAssertEqual(result.matchedWord, "CAT")
    }

    func testDuplicateWordSelectionRejected() {
        let puzzle = makePuzzle()
        let selection = Selection(positions: [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2)
        ])

        let result = ValidateSelectionUseCase().execute(selection: selection, puzzle: puzzle, foundWords: ["CAT"])

        XCTAssertNil(result.matchedWord)
    }

    func testOutOfBoundsPathRejected() {
        let grid = makePuzzle().grid
        let path = SelectionValidationService.path(
            from: GridPosition(row: 0, col: 0),
            to: GridPosition(row: 10, col: 10),
            grid: grid
        )
        XCTAssertNil(path)
    }

    func testMarkWordFoundUpdatesSession() {
        let useCase = MarkWordFoundUseCase()
        let updated = useCase.execute(
            session: Session(dayKey: DayKey(offset: 0), gridSize: 7),
            matchedWord: "cat",
            positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2)]
        )

        XCTAssertTrue(updated.foundWords.contains("CAT"))
        XCTAssertEqual(updated.solvedPositions.count, 3)
        XCTAssertNotNil(updated.startedAt)
    }

    func testComputeScore() {
        let puzzle = makePuzzle()
        let session = Session(dayKey: DayKey(offset: 0), gridSize: 7, foundWords: ["CAT", "DOG"])
        let score = ComputeScoreUseCase().execute(session: session, puzzle: puzzle)

        XCTAssertEqual(score.foundWords, 2)
        XCTAssertEqual(score.totalWords, 4)
        XCTAssertEqual(score.percentage, 0.5)
    }

    func testStreakIncrementsConsecutiveDays() {
        let store = InMemoryKeyValueStore()
        let repository = LocalStreakRepository(store: store)

        _ = repository.markCompleted(dayKey: DayKey(offset: 4), todayKey: DayKey(offset: 4))
        let next = repository.markCompleted(dayKey: DayKey(offset: 5), todayKey: DayKey(offset: 5))

        XCTAssertEqual(next.current, 2)
        XCTAssertEqual(next.lastCompletedOffset, 5)
    }

    func testStreakResetsAfterGap() {
        let store = InMemoryKeyValueStore()
        let repository = LocalStreakRepository(store: store)

        store.set(3, forKey: WordSearchConfig.streakCurrentKey)
        store.set(2, forKey: WordSearchConfig.streakLastCompletedKey)

        let refreshed = repository.refresh(todayKey: DayKey(offset: 7))
        XCTAssertEqual(refreshed.current, 0)
    }

    func testHintRechargeAndClamp() {
        let store = InMemoryKeyValueStore()
        let repository = LocalHintRepository(store: store)

        _ = repository.state(todayKey: DayKey(offset: 0))
        for day in 1...20 {
            _ = repository.state(todayKey: DayKey(offset: day))
        }

        let state = repository.state(todayKey: DayKey(offset: 20))
        XCTAssertEqual(state.available, WordSearchConfig.maxHints)
    }

    func testPuzzleGenerationDeterministic() {
        let first = PuzzleFactory.puzzle(for: DayKey(offset: 50), gridSize: 9)
        let second = PuzzleFactory.puzzle(for: DayKey(offset: 50), gridSize: 9)

        XCTAssertEqual(first.grid, second.grid)
        XCTAssertEqual(first.words, second.words)
    }

    func testWordPathFinderPrefersSolvedCells() {
        let grid = PuzzleGrid(letters: [
            ["C", "A", "T"],
            ["A", "A", "A"],
            ["T", "A", "C"]
        ])
        let solved = Set([
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2)
        ])

        let path = WordPathFinderService.bestPath(for: "CAT", grid: grid, prioritizing: solved)

        XCTAssertEqual(path, [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2)
        ])
    }
}
