import Foundation

public struct GetDailyPuzzleUseCase {
    private let puzzleRepository: PuzzleRepository

    public init(puzzleRepository: PuzzleRepository) {
        self.puzzleRepository = puzzleRepository
    }

    public func execute(dayKey: DayKey, gridSize: Int) -> Puzzle {
        puzzleRepository.puzzle(for: dayKey, gridSize: gridSize)
    }
}

public struct StartDailySessionUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute(dayKey: DayKey, gridSize: Int) -> Session {
        if let record = progressRepository.loadRecord(dayKey: dayKey, preferredGridSize: gridSize) {
            return record.asSession()
        }
        return Session(dayKey: dayKey, gridSize: gridSize)
    }
}

public struct ValidateSelectionUseCase {
    public init() {}

    public func execute(selection: Selection, puzzle: Puzzle, foundWords: Set<String>) -> SelectionValidationResult {
        SelectionValidationService.validate(
            selection: selection,
            puzzle: puzzle,
            alreadyFoundWords: foundWords
        )
    }
}

public struct MarkWordFoundUseCase {
    public init() {}

    public func execute(session: Session, matchedWord: String, positions: [GridPosition], now: Date = Date()) -> Session {
        var updated = session
        updated.foundWords.insert(WordSearchNormalization.normalizedWord(matchedWord))
        updated.solvedPositions.formUnion(positions)
        if updated.startedAt == nil {
            updated.startedAt = now
        }
        return updated
    }
}

public struct ComputeScoreUseCase {
    public init() {}

    public func execute(session: Session, puzzle: Puzzle) -> Score {
        let expected = puzzle.wordSet
        let found = Set(session.foundWords.map(WordSearchNormalization.normalizedWord))
        let count = found.intersection(expected).count
        return Score(foundWords: count, totalWords: expected.count)
    }
}

public struct UpdateStreakUseCase {
    private let streakRepository: StreakRepository

    public init(streakRepository: StreakRepository) {
        self.streakRepository = streakRepository
    }

    public func refresh(todayKey: DayKey) -> Streak {
        streakRepository.refresh(todayKey: todayKey)
    }

    public func markCompleted(dayKey: DayKey, todayKey: DayKey) -> Streak {
        streakRepository.markCompleted(dayKey: dayKey, todayKey: todayKey)
    }
}

public struct SaveProgressUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute(session: Session) {
        let record = AppProgressRecord(
            dayOffset: session.dayKey.offset,
            gridSize: session.gridSize,
            foundWords: Array(session.foundWords),
            solvedPositions: Array(session.solvedPositions),
            startedAt: session.startedAt?.timeIntervalSince1970,
            endedAt: session.endedAt?.timeIntervalSince1970
        )
        progressRepository.save(record)
    }
}

public struct LoadProgressUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute(dayKey: DayKey, preferredGridSize: Int) -> AppProgressRecord? {
        progressRepository.loadRecord(dayKey: dayKey, preferredGridSize: preferredGridSize)
    }
}

public struct LoadSettingsUseCase {
    private let settingsRepository: SettingsRepository

    public init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    public func execute() -> AppSettings {
        settingsRepository.load()
    }
}

public struct SaveSettingsUseCase {
    private let settingsRepository: SettingsRepository

    public init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    public func execute(_ settings: AppSettings) {
        settingsRepository.save(settings)
    }
}

public struct GetCompletedOffsetsUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute() -> Set<Int> {
        progressRepository.completedDayOffsets()
    }
}

public struct LoadAllProgressRecordsUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute() -> [String: AppProgressRecord] {
        progressRepository.loadRecords()
    }
}

public struct SaveProgressRecordUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute(_ record: AppProgressRecord) {
        progressRepository.save(record)
    }
}

public struct ResetProgressRecordUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute(dayKey: DayKey, gridSize: Int) {
        progressRepository.reset(dayKey: dayKey, gridSize: gridSize)
    }
}

public struct MarkCompletedDayUseCase {
    private let progressRepository: ProgressRepository

    public init(progressRepository: ProgressRepository) {
        self.progressRepository = progressRepository
    }

    public func execute(dayKey: DayKey) {
        progressRepository.markCompleted(dayKey: dayKey)
    }
}

public struct LoadStreakUseCase {
    private let streakRepository: StreakRepository

    public init(streakRepository: StreakRepository) {
        self.streakRepository = streakRepository
    }

    public func execute() -> Streak {
        streakRepository.load()
    }
}

public struct LoadHintStateUseCase {
    private let hintRepository: HintRepository

    public init(hintRepository: HintRepository) {
        self.hintRepository = hintRepository
    }

    public func execute(todayKey: DayKey) -> HintState {
        hintRepository.state(todayKey: todayKey)
    }
}

public struct SpendHintUseCase {
    private let hintRepository: HintRepository

    public init(hintRepository: HintRepository) {
        self.hintRepository = hintRepository
    }

    public func execute(todayKey: DayKey) -> Bool {
        hintRepository.spendHint(todayKey: todayKey)
    }
}

public struct RewardCompletionHintUseCase {
    private let hintRepository: HintRepository

    public init(hintRepository: HintRepository) {
        self.hintRepository = hintRepository
    }

    public func execute(dayKey: DayKey, todayKey: DayKey) -> Bool {
        hintRepository.rewardCompletion(dayKey: dayKey, todayKey: todayKey)
    }
}

public struct WasHintRewardedUseCase {
    private let hintRepository: HintRepository

    public init(hintRepository: HintRepository) {
        self.hintRepository = hintRepository
    }

    public func execute(todayKey: DayKey) -> Bool {
        hintRepository.wasRewarded(todayKey: todayKey)
    }
}

public struct GetSharedPuzzleStateUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    public func execute(now: Date, preferredGridSize: Int) -> SharedPuzzleState {
        sharedRepository.loadState(now: now, preferredGridSize: preferredGridSize)
    }
}

public struct SaveSharedPuzzleStateUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    public func execute(_ state: SharedPuzzleState) {
        sharedRepository.saveState(state)
    }
}

public struct UpdateSharedProgressUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    public func execute(
        puzzleIndex: Int,
        gridSize: Int,
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>
    ) {
        sharedRepository.updateProgress(
            puzzleIndex: puzzleIndex,
            gridSize: gridSize,
            foundWords: foundWords,
            solvedPositions: solvedPositions
        )
    }
}

public struct ClearSharedProgressUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    public func execute(puzzleIndex: Int, preferredGridSize: Int) {
        sharedRepository.clearProgress(
            puzzleIndex: puzzleIndex,
            preferredGridSize: preferredGridSize
        )
    }
}

public struct CurrentRotationBoundaryUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    public func execute(now: Date) -> Date {
        sharedRepository.currentRotationBoundary(for: now)
    }
}

public struct ApplySharedTapUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    public func execute(row: Int, col: Int, now: Date, preferredGridSize: Int) -> SharedPuzzleTapResult {
        let current = sharedRepository.loadState(now: now, preferredGridSize: preferredGridSize)
        let next = SharedPuzzleLogicService.applyTap(state: current, row: row, col: col, now: now)
        let changed = next != current
        if changed {
            sharedRepository.saveState(next)
        }
        return SharedPuzzleTapResult(state: next, didChange: changed)
    }
}

public struct ToggleSharedHelpUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    @discardableResult
    public func execute(now: Date, preferredGridSize: Int) -> SharedPuzzleState {
        let current = sharedRepository.loadState(now: now, preferredGridSize: preferredGridSize)
        var next = SharedPuzzleLogicService.resolveExpiredFeedback(state: current, now: now)
        next.isHelpVisible.toggle()
        if next != current {
            sharedRepository.saveState(next)
        }
        return next
    }
}

public struct DismissSharedHintUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    @discardableResult
    public func execute(now: Date, preferredGridSize: Int) -> SharedPuzzleState {
        let current = sharedRepository.loadState(now: now, preferredGridSize: preferredGridSize)
        var next = current
        next.nextHintWord = nil
        next.nextHintExpiresAt = nil
        if next != current {
            sharedRepository.saveState(next)
        }
        return next
    }
}

public struct ResolveSharedFeedbackUseCase {
    private let sharedRepository: SharedPuzzleRepository

    public init(sharedRepository: SharedPuzzleRepository) {
        self.sharedRepository = sharedRepository
    }

    public func execute(now: Date, preferredGridSize: Int) -> SharedPuzzleState {
        let current = sharedRepository.loadState(now: now, preferredGridSize: preferredGridSize)
        let resolved = SharedPuzzleLogicService.resolveExpiredFeedback(state: current, now: now)
        if resolved != current {
            sharedRepository.saveState(resolved)
        }
        return resolved
    }
}
