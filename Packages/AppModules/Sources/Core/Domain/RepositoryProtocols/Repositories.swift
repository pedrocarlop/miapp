import Foundation

public protocol PuzzleRepository {
    func installationDate() -> Date
    func dayOffset(from start: Date, to target: Date) -> DayKey
    func date(from start: Date, dayKey: DayKey) -> Date
    func puzzle(for dayKey: DayKey, gridSize: Int) -> Puzzle
    func normalizedPuzzleIndex(_ index: Int) -> Int
}

public protocol ProgressRepository {
    func loadRecords() -> [String: AppProgressRecord]
    func loadRecord(dayKey: DayKey, preferredGridSize: Int) -> AppProgressRecord?
    func save(_ record: AppProgressRecord)
    func reset(dayKey: DayKey, gridSize: Int)
    func markCompleted(dayKey: DayKey)
    func completedDayOffsets() -> Set<Int>
}

public protocol StreakRepository {
    func load() -> Streak
    func refresh(todayKey: DayKey) -> Streak
    func markCompleted(dayKey: DayKey, todayKey: DayKey) -> Streak
}

public protocol SettingsRepository {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

public protocol HintRepository {
    func state(todayKey: DayKey) -> HintState
    func spendHint(todayKey: DayKey) -> Bool
    func rewardCompletion(dayKey: DayKey, todayKey: DayKey) -> Bool
    func wasRewarded(todayKey: DayKey) -> Bool
}

public protocol SharedPuzzleRepository {
    func loadState(now: Date, preferredGridSize: Int) -> SharedPuzzleState
    func saveState(_ state: SharedPuzzleState)
    func clearProgress(puzzleIndex: Int, preferredGridSize: Int)
    func updateProgress(
        puzzleIndex: Int,
        gridSize: Int,
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>
    )
    func currentRotationBoundary(for now: Date) -> Date
}
