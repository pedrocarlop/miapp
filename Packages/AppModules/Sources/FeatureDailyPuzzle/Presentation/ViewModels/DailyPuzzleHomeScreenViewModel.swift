import Foundation
import Observation
import Core

public struct DailyPuzzleProgressSnapshot: Equatable, Sendable {
    public let foundWords: Set<String>
    public let solvedPositions: Set<GridPosition>

    public init(foundWords: Set<String>, solvedPositions: Set<GridPosition>) {
        self.foundWords = foundWords
        self.solvedPositions = solvedPositions
    }

    public static let empty = DailyPuzzleProgressSnapshot(
        foundWords: [],
        solvedPositions: []
    )
}

public enum DailyPuzzleChallengeTapAction: Equatable, Sendable {
    case openGame
    case unlocked
    case noAction
}

@Observable
@MainActor
public final class DailyPuzzleHomeScreenViewModel {
    private enum Constants {
        static let unlockTapThreshold = 10
    }

    public private(set) var installDate: Date
    public private(set) var selectedOffset: Int?
    public private(set) var sharedState: SharedPuzzleState
    public private(set) var appProgressRecords: [String: AppProgressRecord]
    public private(set) var easterUnlockedOffsets: Set<Int> = []

    private let core: CoreContainer
    private var referenceNow: Date
    private var easterTapCounts: [Int: Int] = [:]

    public init(
        core: CoreContainer,
        preferredGridSize: Int,
        now: Date = Date()
    ) {
        self.core = core
        self.referenceNow = now
        self.installDate = core.installationDate()
        self.selectedOffset = nil
        self.sharedState = core.getSharedPuzzleStateUseCase.execute(
            now: now,
            preferredGridSize: preferredGridSize
        )
        self.appProgressRecords = core.loadAllProgressRecordsUseCase.execute()
        selectTodayIfNeeded()
    }

    public var todayOffset: Int {
        core.dayOffset(from: installDate, to: currentBoundary).offset
    }

    public var minOffset: Int { 0 }
    public var maxOffset: Int { todayOffset + 1 }

    public var carouselOffsets: [Int] {
        Array(minOffset...maxOffset)
    }

    public func setSelectedOffset(_ offset: Int?) {
        selectedOffset = offset
        clampSelectedOffsetIfNeeded()
    }

    public func selectTodayIfNeeded() {
        if selectedOffset == nil {
            selectedOffset = todayOffset
        }
        clampSelectedOffsetIfNeeded()
    }

    public func clampSelectedOffsetIfNeeded() {
        guard let selectedOffset else { return }
        if selectedOffset > maxOffset {
            self.selectedOffset = maxOffset
        }
    }

    public func refresh(
        preferredGridSize: Int,
        now: Date = Date()
    ) {
        referenceNow = now
        installDate = core.installationDate()
        sharedState = core.getSharedPuzzleStateUseCase.execute(
            now: now,
            preferredGridSize: preferredGridSize
        )
        appProgressRecords = core.loadAllProgressRecordsUseCase.execute()

        if sharedState.isCompleted {
            let todayKey = DayKey(offset: todayOffset)
            core.markCompletedDayUseCase.execute(dayKey: todayKey)
            _ = core.updateStreakUseCase.markCompleted(
                dayKey: todayKey,
                todayKey: todayKey
            )
            _ = core.rewardCompletionHintUseCase.execute(
                dayKey: todayKey,
                todayKey: todayKey
            )
        }

        selectTodayIfNeeded()
    }

    public func puzzleDate(for offset: Int) -> Date {
        let delta = offset - todayOffset
        return Calendar.current.date(byAdding: .day, value: delta, to: currentBoundary) ?? currentBoundary
    }

    public func isLocked(offset: Int) -> Bool {
        offset > todayOffset && !easterUnlockedOffsets.contains(offset)
    }

    public func handleChallengeCardTap(offset: Int) -> DailyPuzzleChallengeTapAction {
        if !isLocked(offset: offset) {
            return .openGame
        }

        let nextCount = (easterTapCounts[offset] ?? 0) + 1
        easterTapCounts[offset] = nextCount

        guard nextCount >= Constants.unlockTapThreshold else {
            return .noAction
        }

        easterUnlockedOffsets.insert(offset)
        easterTapCounts[offset] = 0
        return .unlocked
    }

    public func puzzleForOffset(_ offset: Int, preferredGridSize: Int) -> Puzzle {
        if offset == todayOffset, !sharedState.grid.isEmpty, !sharedState.words.isEmpty {
            return Puzzle(
                number: sharedState.puzzleIndex + 1,
                dayKey: DayKey(offset: offset),
                grid: Grid(letters: sharedState.grid),
                words: sharedState.words.map(Word.init(text:))
            )
        }

        if let record = appProgressRecord(for: offset, preferredGridSize: preferredGridSize) {
            return core.puzzle(dayKey: DayKey(offset: offset), gridSize: record.gridSize)
        }

        return core.puzzle(dayKey: DayKey(offset: offset), gridSize: preferredGridSize)
    }

    public func progressForOffset(
        _ offset: Int,
        puzzle: Puzzle,
        preferredGridSize: Int
    ) -> DailyPuzzleProgressSnapshot {
        if offset == todayOffset {
            return progress(from: sharedState, puzzle: puzzle)
        }

        if let record = appProgressRecord(for: offset, preferredGridSize: preferredGridSize) {
            return progress(from: record, puzzle: puzzle)
        }

        return .empty
    }

    public func progressFraction(for offset: Int, preferredGridSize: Int) -> Double {
        let puzzle = puzzleForOffset(offset, preferredGridSize: preferredGridSize)
        let total = max(puzzle.words.count, 1)
        let progress = progressForOffset(offset, puzzle: puzzle, preferredGridSize: preferredGridSize)
        let normalizedFound = Set(progress.foundWords.map { $0.uppercased() })
        let normalizedWords = Set(puzzle.words.map { $0.text.uppercased() })
        let foundCount = normalizedFound.intersection(normalizedWords).count
        return min(max(Double(foundCount) / Double(total), 0), 1)
    }

    public func hoursUntilAvailable(for offset: Int, now: Date = Date()) -> Int? {
        guard offset > todayOffset else { return nil }
        let availableAt = puzzleDate(for: offset)
        let remaining = availableAt.timeIntervalSince(now)
        if remaining <= 0 {
            return 0
        }
        return Int(ceil(remaining / 3600))
    }

    public func initialProgressRecord(for offset: Int, preferredGridSize: Int) -> AppProgressRecord? {
        if offset == todayOffset {
            return appProgressRecord(
                from: sharedState,
                dayOffset: offset,
                gridSize: preferredGridSize
            )
        }
        return appProgressRecord(for: offset, preferredGridSize: preferredGridSize)
    }

    public func sharedPuzzleIndex(for offset: Int) -> Int? {
        offset == todayOffset ? sharedState.puzzleIndex : nil
    }

    private var currentBoundary: Date {
        core.currentRotationBoundaryUseCase.execute(now: referenceNow)
    }

    private func appProgressRecord(
        for offset: Int,
        preferredGridSize: Int
    ) -> AppProgressRecord? {
        let preferredKey = AppProgressRecordKey.make(
            dayOffset: offset,
            gridSize: preferredGridSize
        )
        if let preferred = appProgressRecords[preferredKey] {
            return preferred
        }

        let candidates = appProgressRecords.values.filter { $0.dayOffset == offset }
        return candidates.max { lhs, rhs in
            let lhsActivity = max(lhs.startedAt ?? -1, lhs.endedAt ?? -1)
            let rhsActivity = max(rhs.startedAt ?? -1, rhs.endedAt ?? -1)
            if lhsActivity != rhsActivity {
                return lhsActivity < rhsActivity
            }

            let lhsEnded = lhs.endedAt ?? -1
            let rhsEnded = rhs.endedAt ?? -1
            if lhsEnded != rhsEnded {
                return lhsEnded < rhsEnded
            }

            return lhs.gridSize < rhs.gridSize
        }
    }

    private func progress(
        from sharedState: SharedPuzzleState,
        puzzle: Puzzle
    ) -> DailyPuzzleProgressSnapshot {
        let puzzleWords = Set(puzzle.words.map(\.text))
        let normalizedFound = Set(sharedState.foundWords.map(WordSearchNormalization.normalizedWord))
            .intersection(puzzleWords)
        let normalizedPositions = Set(sharedState.solvedPositions.filter { puzzle.grid.contains($0) })
        return DailyPuzzleProgressSnapshot(
            foundWords: normalizedFound,
            solvedPositions: normalizedPositions
        )
    }

    private func progress(
        from record: AppProgressRecord,
        puzzle: Puzzle
    ) -> DailyPuzzleProgressSnapshot {
        let puzzleWords = Set(puzzle.words.map(\.text))
        let normalizedFound = Set(record.foundWords.map(WordSearchNormalization.normalizedWord))
            .intersection(puzzleWords)
        let normalizedPositions = Set(record.solvedPositions.filter { puzzle.grid.contains($0) })
        return DailyPuzzleProgressSnapshot(
            foundWords: normalizedFound,
            solvedPositions: normalizedPositions
        )
    }

    private func appProgressRecord(
        from sharedState: SharedPuzzleState,
        dayOffset: Int,
        gridSize: Int
    ) -> AppProgressRecord {
        AppProgressRecord(
            dayOffset: dayOffset,
            gridSize: gridSize,
            foundWords: Array(sharedState.foundWords),
            solvedPositions: Array(sharedState.solvedPositions),
            startedAt: nil,
            endedAt: nil
        )
    }
}
