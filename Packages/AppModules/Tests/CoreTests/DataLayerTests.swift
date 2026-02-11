/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Tests/CoreTests/DataLayerTests.swift
 - Rol principal: Valida comportamiento. Ejecuta escenarios y comprueba resultados esperados.
 - Flujo simplificado: Entrada: datos de prueba y condiciones iniciales. | Proceso: ejecutar metodo/flujo bajo test. | Salida: aserciones que deben cumplirse.
 - Tipos clave en este archivo: DataLayerTests
 - Funciones clave en este archivo: testSharedStateDTORoundTrip,testProgressRepositorySaveLoadHappyPath testStreakRepositorySaveLoadHappyPath,testSettingsRepositoryClampNormalization testLegacyMigrationPath,testLegacyV2SlotMigrationPath
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

final class DataLayerTests: XCTestCase {
    func testSharedStateDTORoundTrip() throws {
        let original = SharedPuzzleState(
            grid: [["A", "B"], ["C", "D"]],
            words: ["AB", "CD"],
            gridSize: 2,
            anchor: GridPosition(row: 0, col: 0),
            foundWords: ["AB"],
            solvedPositions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)],
            puzzleIndex: 1,
            isHelpVisible: true,
            feedback: SelectionFeedback(kind: .correct, positions: [GridPosition(row: 0, col: 0)], expiresAt: Date()),
            pendingWord: nil,
            pendingSolvedPositions: [],
            nextHintWord: "CD",
            nextHintExpiresAt: nil
        )

        let dto = StateMappers.toDTO(original)
        let data = try JSONEncoder().encode(dto)
        let decodedDTO = try JSONDecoder().decode(SharedPuzzleStateDTO.self, from: data)
        let mapped = StateMappers.toDomain(decodedDTO)

        XCTAssertEqual(mapped.grid, original.grid)
        XCTAssertEqual(mapped.words, original.words)
        XCTAssertEqual(mapped.foundWords, original.foundWords)
    }

    func testProgressRepositorySaveLoadHappyPath() {
        let store = InMemoryKeyValueStore()
        let repository = LocalProgressRepository(store: store)

        let record = AppProgressRecord(
            dayOffset: 2,
            gridSize: 8,
            foundWords: ["CAT"],
            solvedPositions: [GridPosition(row: 0, col: 0)],
            startedAt: 100,
            endedAt: nil
        )

        repository.save(record)
        let loaded = repository.loadRecord(dayKey: DayKey(offset: 2), preferredGridSize: 8)

        XCTAssertEqual(loaded?.dayOffset, 2)
        XCTAssertEqual(loaded?.gridSize, 8)
        XCTAssertEqual(loaded?.foundWords, ["CAT"])
    }

    func testStreakRepositorySaveLoadHappyPath() {
        let store = InMemoryKeyValueStore()
        let repository = LocalStreakRepository(store: store)

        let updated = repository.markCompleted(dayKey: DayKey(offset: 3), todayKey: DayKey(offset: 3))
        let loaded = repository.load()

        XCTAssertEqual(updated.current, 1)
        XCTAssertEqual(loaded.current, 1)
        XCTAssertEqual(loaded.lastCompletedOffset, 3)
    }

    func testSettingsRepositoryClampNormalization() {
        let store = InMemoryKeyValueStore()
        store.set(100, forKey: WordSearchConfig.gridSizeKey)
        store.set(-100, forKey: WordSearchConfig.dailyRefreshMinutesKey)

        let repository = LocalSettingsRepository(store: store)
        let settings = repository.load()

        XCTAssertEqual(settings.gridSize, WordSearchConfig.maxGridSize)
        XCTAssertEqual(settings.dailyRefreshMinutes, 0)
    }

    func testLegacyMigrationPath() throws {
        let store = InMemoryKeyValueStore()

        let legacy = LegacyPuzzleStateV1DTO(
            grid: [["A", "B"], ["C", "D"]],
            words: ["AB"],
            foundWords: ["AB"]
        )
        let data = try JSONEncoder().encode(legacy)
        store.set(data, forKey: WordSearchConfig.legacyStateKey)

        let repository = LocalSharedPuzzleRepository(store: store)
        let state = repository.loadState(now: Date(), preferredGridSize: 7)

        XCTAssertFalse(state.grid.isEmpty)
        XCTAssertTrue(state.foundWords.contains("AB"))
        XCTAssertNil(store.data(forKey: WordSearchConfig.legacyStateKey))
    }

    func testLegacyV2SlotMigrationPath() throws {
        let store = InMemoryKeyValueStore()

        let legacy = LegacySlotStateDTO(
            grid: [["C", "A", "T"], ["X", "X", "X"], ["D", "O", "G"]],
            words: ["CAT", "DOG"],
            foundWords: ["CAT"],
            solvedPositions: [
                LegacyPositionDTO(r: 0, c: 0),
                LegacyPositionDTO(r: 0, c: 1),
                LegacyPositionDTO(r: 0, c: 2)
            ],
            puzzleIndex: 4
        )
        let data = try JSONEncoder().encode(legacy)
        store.set(data, forKey: WordSearchConfig.legacySlotStateKeys[0])

        let repository = LocalSharedPuzzleRepository(store: store)
        let state = repository.loadState(now: Date(), preferredGridSize: 7)

        XCTAssertEqual(state.puzzleIndex, PuzzleFactory.normalizedPuzzleIndex(4))
        XCTAssertTrue(state.foundWords.contains("CAT"))
        XCTAssertTrue(state.solvedPositions.contains(GridPosition(row: 0, col: 0)))
        XCTAssertNil(store.data(forKey: WordSearchConfig.legacySlotStateKeys[0]))
    }

    func testLoadAllProgressRecordsUseCase() {
        let store = InMemoryKeyValueStore()
        let repository = LocalProgressRepository(store: store)
        repository.save(AppProgressRecord(dayOffset: 1, gridSize: 7, foundWords: ["CAT"], solvedPositions: [], startedAt: nil, endedAt: nil))
        repository.save(AppProgressRecord(dayOffset: 2, gridSize: 8, foundWords: ["DOG"], solvedPositions: [], startedAt: nil, endedAt: nil))

        let useCase = LoadAllProgressRecordsUseCase(progressRepository: repository)
        let records = useCase.execute()

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[AppProgressRecordKey.make(dayOffset: 1, gridSize: 7)]?.foundWords, ["CAT"])
    }

    func testLoadSaveSettingsUseCasesRoundTrip() {
        let store = InMemoryKeyValueStore()
        let repository = LocalSettingsRepository(store: store)
        let loadUseCase = LoadSettingsUseCase(settingsRepository: repository)
        let saveUseCase = SaveSettingsUseCase(settingsRepository: repository)
        let expectedLanguage = AppLanguage.resolved()
        let nonDeviceLanguage = AppLanguage.allCases.first(where: { $0 != expectedLanguage }) ?? .english

        var settings = loadUseCase.execute()
        settings.gridSize = 9
        settings.appearanceMode = .dark
        settings.wordHintMode = .definition
        settings.appLanguage = nonDeviceLanguage
        settings.dailyRefreshMinutes = 300
        settings.enableCelebrations = false
        settings.enableHaptics = false
        settings.enableSound = true
        settings.celebrationIntensity = .high
        saveUseCase.execute(settings)

        let reloaded = loadUseCase.execute()
        XCTAssertEqual(reloaded.gridSize, 9)
        XCTAssertEqual(reloaded.appearanceMode, .dark)
        XCTAssertEqual(reloaded.wordHintMode, .definition)
        XCTAssertEqual(reloaded.appLanguage, expectedLanguage)
        XCTAssertEqual(reloaded.dailyRefreshMinutes, 300)
        XCTAssertFalse(reloaded.enableCelebrations)
        XCTAssertFalse(reloaded.enableHaptics)
        XCTAssertTrue(reloaded.enableSound)
        XCTAssertEqual(reloaded.celebrationIntensity, .high)
    }

    func testSavingLanguageUpdatesAppLocalizationEvenWithInMemoryStore() {
        withIsolatedLanguageDefaults {
            let expectedLanguage = AppLanguage.resolved()
            let nonDeviceLanguage = AppLanguage.allCases.first(where: { $0 != expectedLanguage }) ?? .english
            AppLocalization.setCurrentLanguage(nonDeviceLanguage)
            XCTAssertEqual(AppLocalization.currentLanguage, nonDeviceLanguage)

            let store = InMemoryKeyValueStore()
            let repository = LocalSettingsRepository(store: store)

            var settings = repository.load()
            settings.appLanguage = nonDeviceLanguage
            repository.save(settings)

            XCTAssertEqual(AppLocalization.currentLanguage, expectedLanguage)

            let implicitLanguagePuzzle = PuzzleFactory.puzzle(
                for: DayKey(offset: 0),
                gridSize: 9
            )
            let explicitResolvedPuzzle = PuzzleFactory.puzzle(
                for: DayKey(offset: 0),
                gridSize: 9,
                locale: expectedLanguage.locale
            )

            XCTAssertEqual(
                implicitLanguagePuzzle.words.map(\.text),
                explicitResolvedPuzzle.words.map(\.text)
            )
        }
    }

    func testLoadSettingsUsesDeviceLanguageEvenWhenStoredValueDiffers() {
        withIsolatedLanguageDefaults {
            let expectedLanguage = AppLanguage.resolved()
            let nonDeviceLanguage = AppLanguage.allCases.first(where: { $0 != expectedLanguage }) ?? .english
            let store = InMemoryKeyValueStore()
            store.set(nonDeviceLanguage.rawValue, forKey: WordSearchConfig.appLanguageKey)

            let repository = LocalSettingsRepository(store: store)
            let loaded = repository.load()

            XCTAssertEqual(loaded.appLanguage, expectedLanguage)
            XCTAssertEqual(AppLocalization.currentLanguage, expectedLanguage)
        }
    }

    func testToggleSharedHelpUseCaseTogglesFlag() {
        let store = InMemoryKeyValueStore()
        let repository = LocalSharedPuzzleRepository(store: store)
        let useCase = ToggleSharedHelpUseCase(sharedRepository: repository)
        let now = Date(timeIntervalSince1970: 1000)

        let first = useCase.execute(now: now, preferredGridSize: 7)
        XCTAssertTrue(first.isHelpVisible)

        let second = useCase.execute(now: now.addingTimeInterval(1), preferredGridSize: 7)
        XCTAssertFalse(second.isHelpVisible)
    }

    func testDismissSharedHintUseCaseClearsHint() {
        let store = InMemoryKeyValueStore()
        let repository = LocalSharedPuzzleRepository(store: store)
        let now = Date(timeIntervalSince1970: 2000)

        var seeded = repository.loadState(now: now, preferredGridSize: 7)
        seeded.nextHintWord = "CAT"
        seeded.nextHintExpiresAt = now.addingTimeInterval(120)
        repository.saveState(seeded)

        let useCase = DismissSharedHintUseCase(sharedRepository: repository)
        let result = useCase.execute(now: now, preferredGridSize: 7)

        XCTAssertNil(result.nextHintWord)
        XCTAssertNil(result.nextHintExpiresAt)
        let reloaded = repository.loadState(now: now, preferredGridSize: 7)
        XCTAssertNil(reloaded.nextHintWord)
        XCTAssertNil(reloaded.nextHintExpiresAt)
    }

    func testSharedProgressPersistsAcrossUseCases() {
        let store = InMemoryKeyValueStore()
        let repository = LocalSharedPuzzleRepository(store: store)
        let getState = GetSharedPuzzleStateUseCase(sharedRepository: repository)
        let updateProgress = UpdateSharedProgressUseCase(sharedRepository: repository)
        let now = Date(timeIntervalSince1970: 2500)

        let initial = getState.execute(now: now, preferredGridSize: 7)
        let targetWord = initial.words.first ?? "CAT"
        let validPosition = GridPosition(row: 0, col: 0)
        let outOfBounds = GridPosition(row: 99, col: 99)

        updateProgress.execute(
            puzzleIndex: initial.puzzleIndex,
            gridSize: initial.gridSize,
            foundWords: [targetWord, "NOT_IN_PUZZLE"],
            solvedPositions: [validPosition, outOfBounds]
        )

        let reloaded = getState.execute(
            now: now.addingTimeInterval(1),
            preferredGridSize: initial.gridSize
        )

        XCTAssertEqual(reloaded.foundWords, Set([WordSearchNormalization.normalizedWord(targetWord)]))
        XCTAssertTrue(reloaded.solvedPositions.contains(validPosition))
        XCTAssertFalse(reloaded.solvedPositions.contains(outOfBounds))
    }

    func testSharedRepositoryRotatesPuzzleWhenBoundaryAdvances() {
        let store = InMemoryKeyValueStore()
        let repository = LocalSharedPuzzleRepository(store: store)
        let now = Date(timeIntervalSince1970: 3_000_000)

        var seeded = repository.loadState(now: now, preferredGridSize: 7)
        seeded.puzzleIndex = 5
        seeded.foundWords = ["CAT"]
        seeded.solvedPositions = [GridPosition(row: 0, col: 0)]
        repository.saveState(seeded)

        let currentBoundary = repository.currentRotationBoundary(for: now)
        let staleBoundary = Calendar.current.date(byAdding: .day, value: -2, to: currentBoundary) ?? currentBoundary
        store.set(staleBoundary.timeIntervalSince1970, forKey: WordSearchConfig.rotationBoundaryKey)

        let rotated = repository.loadState(now: now, preferredGridSize: 7)

        XCTAssertEqual(rotated.puzzleIndex, PuzzleFactory.normalizedPuzzleIndex(7))
        XCTAssertTrue(rotated.foundWords.isEmpty)
        XCTAssertTrue(rotated.solvedPositions.isEmpty)
        XCTAssertEqual(
            store.double(forKey: WordSearchConfig.rotationBoundaryKey),
            currentBoundary.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testProgressRecordResolverPrefersPreferredGridSizeKey() {
        let preferred = AppProgressRecord(
            dayOffset: 3,
            gridSize: 7,
            foundWords: ["CAT"],
            solvedPositions: [],
            startedAt: 10,
            endedAt: 20
        )
        let newerOtherGrid = AppProgressRecord(
            dayOffset: 3,
            gridSize: 9,
            foundWords: ["DOG"],
            solvedPositions: [],
            startedAt: 100,
            endedAt: 120
        )
        let records: [String: AppProgressRecord] = [
            AppProgressRecordKey.make(dayOffset: preferred.dayOffset, gridSize: preferred.gridSize): preferred,
            AppProgressRecordKey.make(dayOffset: newerOtherGrid.dayOffset, gridSize: newerOtherGrid.gridSize): newerOtherGrid
        ]

        let resolved = ProgressRecordResolver.resolve(
            dayOffset: 3,
            preferredGridSize: 7,
            records: records
        )

        XCTAssertEqual(resolved?.gridSize, 7)
        XCTAssertEqual(resolved?.foundWords, ["CAT"])
    }

    func testProgressRecordResolverFallsBackToMostRecentActivity() {
        let older = AppProgressRecord(
            dayOffset: 8,
            gridSize: 7,
            foundWords: ["CAT"],
            solvedPositions: [],
            startedAt: 10,
            endedAt: 40
        )
        let newer = AppProgressRecord(
            dayOffset: 8,
            gridSize: 9,
            foundWords: ["DOG"],
            solvedPositions: [],
            startedAt: 50,
            endedAt: 80
        )
        let records: [String: AppProgressRecord] = [
            AppProgressRecordKey.make(dayOffset: older.dayOffset, gridSize: older.gridSize): older,
            AppProgressRecordKey.make(dayOffset: newer.dayOffset, gridSize: newer.gridSize): newer
        ]

        let resolved = ProgressRecordResolver.resolve(
            dayOffset: 8,
            preferredGridSize: 10,
            records: records
        )

        XCTAssertEqual(resolved?.gridSize, 9)
        XCTAssertEqual(resolved?.foundWords, ["DOG"])
    }

    private func withIsolatedLanguageDefaults(_ body: () -> Void) {
        let key = WordSearchConfig.appLanguageKey
        let suiteDefaults = UserDefaults(suiteName: WordSearchConfig.suiteName)
        let previousSuiteValue = suiteDefaults?.string(forKey: key)
        let previousStandardValue = UserDefaults.standard.string(forKey: key)

        suiteDefaults?.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        AppLocalization.resetCachedLanguageForTesting()

        defer {
            if let previousSuiteValue {
                suiteDefaults?.set(previousSuiteValue, forKey: key)
            } else {
                suiteDefaults?.removeObject(forKey: key)
            }

            if let previousStandardValue {
                UserDefaults.standard.set(previousStandardValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }

            AppLocalization.resetCachedLanguageForTesting()
        }

        body()
    }
}
