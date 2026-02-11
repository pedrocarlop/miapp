/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/FeatureDailyPuzzleTests/DailyPuzzleGameSessionViewModelTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: DailyPuzzleGameSessionViewModelTests
 - Funciones clave en este archivo: makePuzzle,testStartIfNeededSetsStartedAt testFinalizeSelectionMarksWordAndCompletesPuzzle,testFinalizeSelectionRejectsInvalidPath testResetClearsSessionState
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
import Core
@testable import FeatureDailyPuzzle

@MainActor
final class DailyPuzzleGameSessionViewModelTests: XCTestCase {
    private func makePuzzle() -> Puzzle {
        Puzzle(
            number: 1,
            dayKey: DayKey(offset: 0),
            grid: PuzzleGrid(letters: [
                ["C", "A", "T"],
                ["X", "X", "X"],
                ["D", "O", "G"]
            ]),
            words: [Word(text: "CAT")]
        )
    }

    func testStartIfNeededSetsStartedAt() {
        let viewModel = DailyPuzzleGameSessionViewModel(
            dayKey: DayKey(offset: 0),
            gridSize: 3,
            puzzle: makePuzzle(),
            foundWords: [],
            solvedPositions: [],
            startedAt: nil,
            endedAt: nil
        )

        let now = Date(timeIntervalSince1970: 42)
        XCTAssertTrue(viewModel.startIfNeeded(now: now))
        XCTAssertEqual(viewModel.startedAt, now)
        XCTAssertFalse(viewModel.startIfNeeded(now: now))
    }

    func testFinalizeSelectionMarksWordAndCompletesPuzzle() {
        let viewModel = DailyPuzzleGameSessionViewModel(
            dayKey: DayKey(offset: 0),
            gridSize: 3,
            puzzle: makePuzzle(),
            foundWords: [],
            solvedPositions: [],
            startedAt: nil,
            endedAt: nil
        )

        let now = Date(timeIntervalSince1970: 100)
        let outcome = viewModel.finalizeSelection([
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2)
        ], now: now)

        if case let .correct(matchedWord) = outcome.kind {
            XCTAssertEqual(matchedWord, "CAT")
        } else {
            XCTFail("Expected correct selection outcome")
        }
        XCTAssertTrue(outcome.completedPuzzleNow)
        XCTAssertTrue(viewModel.foundWords.contains("CAT"))
        XCTAssertNotNil(viewModel.endedAt)
    }

    func testFinalizeSelectionRejectsInvalidPath() {
        let viewModel = DailyPuzzleGameSessionViewModel(
            dayKey: DayKey(offset: 0),
            gridSize: 3,
            puzzle: makePuzzle(),
            foundWords: [],
            solvedPositions: [],
            startedAt: nil,
            endedAt: nil
        )

        let outcome = viewModel.finalizeSelection([
            GridPosition(row: 0, col: 0),
            GridPosition(row: 2, col: 2)
        ])

        if case .incorrect = outcome.kind {
            XCTAssertFalse(outcome.completedPuzzleNow)
        } else {
            XCTFail("Expected incorrect selection outcome")
        }
    }

    func testResetClearsSessionState() {
        let viewModel = DailyPuzzleGameSessionViewModel(
            dayKey: DayKey(offset: 0),
            gridSize: 3,
            puzzle: makePuzzle(),
            foundWords: ["CAT"],
            solvedPositions: [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 0, col: 1),
                GridPosition(row: 0, col: 2)
            ],
            startedAt: Date(timeIntervalSince1970: 20),
            endedAt: Date(timeIntervalSince1970: 21)
        )

        viewModel.reset()

        XCTAssertTrue(viewModel.foundWords.isEmpty)
        XCTAssertTrue(viewModel.solvedPositions.isEmpty)
        XCTAssertNil(viewModel.startedAt)
        XCTAssertNil(viewModel.endedAt)
    }
}
