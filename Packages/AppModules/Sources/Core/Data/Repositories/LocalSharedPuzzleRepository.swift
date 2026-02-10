import Foundation

public final class LocalSharedPuzzleRepository: SharedPuzzleRepository {
    private let store: KeyValueStore
    private let onMutation: (() -> Void)?

    public init(store: KeyValueStore, onMutation: (() -> Void)? = nil) {
        self.store = store
        self.onMutation = onMutation
    }

    public func loadState(now: Date, preferredGridSize: Int) -> SharedPuzzleState {
        migrateLegacyIfNeeded()

        let clampedSize = PuzzleFactory.clampGridSize(preferredGridSize)
        let decoded = decodeState()
        var state = decoded ?? makeState(puzzleIndex: 0, gridSize: clampedSize)
        let original = state

        state = normalizedState(state)
        state = applyExternalResetIfNeeded(state: state)
        state = applyDailyRotationIfNeeded(
            state: state,
            now: now,
            preferredGridSize: clampedSize
        )
        state = SharedPuzzleLogicService.resolveExpiredFeedback(state: state, now: now)

        if decoded == nil || state != original {
            saveState(state)
        }

        return state
    }

    public func saveState(_ state: SharedPuzzleState) {
        let dto = StateMappers.toDTO(state)
        guard let data = try? JSONEncoder().encode(dto) else {
            AppLogger.error(
                "Failed to encode shared puzzle state",
                category: .persistence,
                metadata: [
                    "key": WordSearchConfig.stateKey,
                    "puzzleIndex": "\(state.puzzleIndex)",
                    "gridSize": "\(state.gridSize)"
                ]
            )
            return
        }
        store.set(data, forKey: WordSearchConfig.stateKey)
        onMutation?()
    }

    public func clearProgress(puzzleIndex: Int, preferredGridSize: Int) {
        let now = Date()
        let state = loadState(now: now, preferredGridSize: preferredGridSize)
        guard state.puzzleIndex == puzzleIndex else { return }

        let cleared = clearedState(from: state)
        saveState(cleared)
    }

    public func updateProgress(
        puzzleIndex: Int,
        gridSize: Int,
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>
    ) {
        let now = Date()
        var state = loadState(now: now, preferredGridSize: gridSize)
        guard state.puzzleIndex == puzzleIndex else { return }

        let puzzleWords = Set(state.words.map(WordSearchNormalization.normalizedWord))
        let normalizedFound = Set(foundWords.map(WordSearchNormalization.normalizedWord)).intersection(puzzleWords)
        let maxRow = state.grid.count
        let maxCol = state.grid.first?.count ?? 0

        let normalizedPositions = solvedPositions.filter {
            $0.row >= 0 && $0.col >= 0 && $0.row < maxRow && $0.col < maxCol
        }

        state.foundWords = normalizedFound
        state.solvedPositions = normalizedPositions
        saveState(state)
    }

    public func currentRotationBoundary(for now: Date) -> Date {
        let minutes = minutesFromMidnight()
        return DailyRefreshClock.currentRotationBoundary(now: now, minutesFromMidnight: minutes)
    }

    private func decodeState() -> SharedPuzzleState? {
        guard let data = store.data(forKey: WordSearchConfig.stateKey) else {
            return nil
        }

        guard let dto = try? JSONDecoder().decode(SharedPuzzleStateDTO.self, from: data) else {
            AppLogger.error(
                "Failed to decode shared puzzle state",
                category: .persistence,
                metadata: [
                    "key": WordSearchConfig.stateKey,
                    "bytes": "\(data.count)"
                ]
            )
            return nil
        }

        return StateMappers.toDomain(dto)
    }

    private func makeState(puzzleIndex: Int, gridSize: Int) -> SharedPuzzleState {
        let normalized = PuzzleFactory.normalizedPuzzleIndex(puzzleIndex)
        let size = PuzzleFactory.clampGridSize(gridSize)
        let puzzle = PuzzleFactory.puzzle(for: DayKey(offset: normalized), gridSize: size)

        return SharedPuzzleState(
            grid: puzzle.grid.letters,
            words: puzzle.words.map(\.text),
            gridSize: size,
            anchor: nil,
            foundWords: [],
            solvedPositions: [],
            puzzleIndex: normalized,
            isHelpVisible: false,
            feedback: nil,
            pendingWord: nil,
            pendingSolvedPositions: [],
            nextHintWord: nil,
            nextHintExpiresAt: nil
        )
    }

    private func normalizedState(_ state: SharedPuzzleState) -> SharedPuzzleState {
        let size = PuzzleFactory.clampGridSize(state.gridSize)

        guard state.gridSize == size else {
            return makeState(puzzleIndex: state.puzzleIndex, gridSize: size)
        }

        guard state.grid.count == size,
              state.grid.allSatisfy({ $0.count == size }) else {
            return makeState(puzzleIndex: state.puzzleIndex, gridSize: size)
        }

        return state
    }

    private func applyExternalResetIfNeeded(state: SharedPuzzleState) -> SharedPuzzleState {
        let requestToken = store.double(forKey: WordSearchConfig.resetRequestKey)
        let appliedToken = store.double(forKey: WordSearchConfig.lastAppliedResetKey)

        guard requestToken > appliedToken else {
            return state
        }

        store.set(requestToken, forKey: WordSearchConfig.lastAppliedResetKey)
        return clearedState(from: state)
    }

    private func clearedState(from state: SharedPuzzleState) -> SharedPuzzleState {
        let size = PuzzleFactory.clampGridSize(state.gridSize)
        let puzzle = PuzzleFactory.puzzle(for: DayKey(offset: state.puzzleIndex), gridSize: size)

        return SharedPuzzleState(
            grid: puzzle.grid.letters,
            words: puzzle.words.map(\.text),
            gridSize: size,
            anchor: nil,
            foundWords: [],
            solvedPositions: [],
            puzzleIndex: state.puzzleIndex,
            isHelpVisible: false,
            feedback: nil,
            pendingWord: nil,
            pendingSolvedPositions: [],
            nextHintWord: nil,
            nextHintExpiresAt: nil
        )
    }

    private func applyDailyRotationIfNeeded(
        state: SharedPuzzleState,
        now: Date,
        preferredGridSize: Int
    ) -> SharedPuzzleState {
        let boundary = currentRotationBoundary(for: now)
        let boundaryTimestamp = boundary.timeIntervalSince1970

        guard let existing = store.object(forKey: WordSearchConfig.rotationBoundaryKey) as? Double else {
            store.set(boundaryTimestamp, forKey: WordSearchConfig.rotationBoundaryKey)
            return state
        }

        if existing >= boundaryTimestamp {
            return state
        }

        let previousBoundary = Date(timeIntervalSince1970: existing)
        let steps = max(DailyRefreshClock.rotationSteps(from: previousBoundary, to: boundary), 1)
        let nextIndex = PuzzleFactory.normalizedPuzzleIndex(state.puzzleIndex + steps)

        store.set(boundaryTimestamp, forKey: WordSearchConfig.rotationBoundaryKey)
        return makeState(puzzleIndex: nextIndex, gridSize: preferredGridSize)
    }

    private func minutesFromMidnight() -> Int {
        guard let stored = store.object(forKey: WordSearchConfig.dailyRefreshMinutesKey) as? Int else {
            store.set(WordSearchConfig.defaultDailyRefreshMinutes, forKey: WordSearchConfig.dailyRefreshMinutesKey)
            return WordSearchConfig.defaultDailyRefreshMinutes
        }

        let clamped = DailyRefreshClock.clampMinutes(stored)
        if clamped != stored {
            store.set(clamped, forKey: WordSearchConfig.dailyRefreshMinutesKey)
        }
        return clamped
    }

    private func migrateLegacyIfNeeded() {
        if store.data(forKey: WordSearchConfig.stateKey) != nil {
            return
        }

        if let slotData = store.data(forKey: WordSearchConfig.legacySlotStateKeys[0]) {
            if let legacy = try? JSONDecoder().decode(LegacySlotStateDTO.self, from: slotData),
               let puzzle = makePuzzleFromLegacy(legacy.grid, words: legacy.words) {
                let size = PuzzleFactory.clampGridSize(puzzle.grid.letters.count)
                let migrated = SharedPuzzleState(
                    grid: puzzle.grid.letters,
                    words: puzzle.words.map(\.text),
                    gridSize: size,
                    anchor: nil,
                    foundWords: Set(legacy.foundWords.map(WordSearchNormalization.normalizedWord)),
                    solvedPositions: Set(legacy.solvedPositions.map { GridPosition(row: $0.r, col: $0.c) }),
                    puzzleIndex: PuzzleFactory.normalizedPuzzleIndex(legacy.puzzleIndex),
                    isHelpVisible: false,
                    feedback: nil,
                    pendingWord: nil,
                    pendingSolvedPositions: [],
                    nextHintWord: nil,
                    nextHintExpiresAt: nil
                )
                saveState(migrated)
                store.removeObject(forKey: WordSearchConfig.legacyStateKey)
                store.removeObject(forKey: WordSearchConfig.legacyMigrationFlagKey)
                cleanupLegacySlotKeys()
                AppLogger.info(
                    "Migrated legacy slot state",
                    category: .migration,
                    metadata: ["sourceKey": WordSearchConfig.legacySlotStateKeys[0]]
                )
                return
            }

            AppLogger.error(
                "Failed to decode or normalize legacy slot state",
                category: .migration,
                metadata: ["sourceKey": WordSearchConfig.legacySlotStateKeys[0]]
            )
        }

        if let legacyData = store.data(forKey: WordSearchConfig.legacyStateKey) {
            if let legacy = try? JSONDecoder().decode(LegacyPuzzleStateV1DTO.self, from: legacyData),
               let puzzle = makePuzzleFromLegacy(legacy.grid, words: legacy.words) {
                let size = PuzzleFactory.clampGridSize(puzzle.grid.letters.count)
                let migrated = SharedPuzzleState(
                    grid: puzzle.grid.letters,
                    words: puzzle.words.map(\.text),
                    gridSize: size,
                    anchor: nil,
                    foundWords: Set(legacy.foundWords.map(WordSearchNormalization.normalizedWord)),
                    solvedPositions: [],
                    puzzleIndex: 0,
                    isHelpVisible: false,
                    feedback: nil,
                    pendingWord: nil,
                    pendingSolvedPositions: [],
                    nextHintWord: nil,
                    nextHintExpiresAt: nil
                )
                saveState(migrated)
                store.removeObject(forKey: WordSearchConfig.legacyStateKey)
                store.removeObject(forKey: WordSearchConfig.legacyMigrationFlagKey)
                cleanupLegacySlotKeys()
                AppLogger.info(
                    "Migrated legacy v1 state",
                    category: .migration,
                    metadata: ["sourceKey": WordSearchConfig.legacyStateKey]
                )
                return
            }

            AppLogger.error(
                "Failed to decode or normalize legacy v1 state",
                category: .migration,
                metadata: ["sourceKey": WordSearchConfig.legacyStateKey]
            )
        }
    }

    private func cleanupLegacySlotKeys() {
        for key in WordSearchConfig.legacySlotStateKeys + WordSearchConfig.legacySlotIndexKeys {
            store.removeObject(forKey: key)
        }
    }

    private func makePuzzleFromLegacy(_ grid: [[String]], words: [String]) -> Puzzle? {
        guard !grid.isEmpty else { return nil }
        let size = grid.count
        guard grid.allSatisfy({ $0.count == size }) else { return nil }

        let safeWords = words
            .map(WordSearchNormalization.normalizedWord)
            .filter { !$0.isEmpty && $0.count <= size }

        return Puzzle(
            number: 1,
            dayKey: DayKey(offset: 0),
            grid: PuzzleGrid(letters: grid),
            words: safeWords.map(Word.init(text:))
        )
    }
}
