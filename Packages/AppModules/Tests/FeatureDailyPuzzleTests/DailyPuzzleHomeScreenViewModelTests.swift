/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/FeatureDailyPuzzleTests/DailyPuzzleHomeScreenViewModelTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: DailyPuzzleHomeScreenViewModelTests
 - Funciones clave en este archivo: testLockedChallengeUnlocksOnTenthTapAndOpensOnNextTap,testInitialProgressRecordForTodayUsesSharedStateProgress testChallengeCardsFollowCarouselOffsets,testUnlockTapUpdatesCachedChallengeCardLockState
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
final class DailyPuzzleHomeScreenViewModelTests: XCTestCase {
    func testLockedChallengeUnlocksOnTenthTapAndOpensOnNextTap() {
        let core = CoreContainer(store: InMemoryKeyValueStore())
        let viewModel = DailyPuzzleHomeScreenViewModel(core: core, preferredGridSize: 7)
        let lockedOffset = viewModel.todayOffset + 1

        for _ in 0..<9 {
            XCTAssertEqual(viewModel.handleChallengeCardTap(offset: lockedOffset), .noAction)
        }

        XCTAssertEqual(viewModel.handleChallengeCardTap(offset: lockedOffset), .unlocked)
        XCTAssertFalse(viewModel.isLocked(offset: lockedOffset))
        XCTAssertEqual(viewModel.handleChallengeCardTap(offset: lockedOffset), .openGame)
    }

    func testInitialProgressRecordForTodayUsesSharedStateProgress() {
        let now = Date(timeIntervalSince1970: 10_000)
        let core = CoreContainer(store: InMemoryKeyValueStore())

        var shared = core.getSharedPuzzleStateUseCase.execute(now: now, preferredGridSize: 7)
        shared.foundWords = ["CAT"]
        shared.solvedPositions = [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)]
        core.saveSharedPuzzleStateUseCase.execute(shared)

        let viewModel = DailyPuzzleHomeScreenViewModel(core: core, preferredGridSize: 7, now: now)
        let record = viewModel.initialProgressRecord(
            for: viewModel.todayOffset,
            preferredGridSize: 7
        )

        XCTAssertEqual(Set(record?.foundWords ?? []), ["CAT"])
        XCTAssertEqual(Set(record?.solvedPositions ?? []), Set(shared.solvedPositions))
    }

    func testChallengeCardsFollowCarouselOffsets() {
        let now = Date(timeIntervalSince1970: 30_000)
        let core = CoreContainer(store: InMemoryKeyValueStore())
        let viewModel = DailyPuzzleHomeScreenViewModel(
            core: core,
            preferredGridSize: 7,
            now: now
        )

        XCTAssertEqual(viewModel.challengeCards.map(\.offset), viewModel.carouselOffsets)
        XCTAssertTrue(viewModel.challengeCards.contains { !$0.words.isEmpty })
    }

    func testUnlockTapUpdatesCachedChallengeCardLockState() {
        let core = CoreContainer(store: InMemoryKeyValueStore())
        let viewModel = DailyPuzzleHomeScreenViewModel(core: core, preferredGridSize: 7)
        let lockedOffset = viewModel.todayOffset + 1

        XCTAssertTrue(viewModel.challengeCards.contains { $0.offset == lockedOffset && $0.isLocked })

        for _ in 0..<10 {
            _ = viewModel.handleChallengeCardTap(offset: lockedOffset)
        }

        XCTAssertTrue(viewModel.challengeCards.contains { $0.offset == lockedOffset && !$0.isLocked })
    }
}
