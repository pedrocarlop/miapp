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

        var settings = loadUseCase.execute()
        settings.gridSize = 9
        settings.appearanceMode = .dark
        settings.wordHintMode = .definition
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
        XCTAssertEqual(reloaded.dailyRefreshMinutes, 300)
        XCTAssertFalse(reloaded.enableCelebrations)
        XCTAssertFalse(reloaded.enableHaptics)
        XCTAssertTrue(reloaded.enableSound)
        XCTAssertEqual(reloaded.celebrationIntensity, .high)
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
    }
}
