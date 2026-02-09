import Foundation
import Observation
import Core

public enum DailyPuzzleSelectionOutcomeKind: Sendable {
    case ignored
    case incorrect
    case correct(matchedWord: String)
}

public struct DailyPuzzleSelectionOutcome: Sendable {
    public let kind: DailyPuzzleSelectionOutcomeKind
    public let completedPuzzleNow: Bool

    public init(kind: DailyPuzzleSelectionOutcomeKind, completedPuzzleNow: Bool) {
        self.kind = kind
        self.completedPuzzleNow = completedPuzzleNow
    }
}

@Observable
@MainActor
public final class DailyPuzzleGameSessionViewModel {
    public let dayKey: DayKey
    public let gridSize: Int
    public let puzzle: Puzzle

    public private(set) var foundWords: Set<String>
    public private(set) var solvedPositions: Set<GridPosition>
    public private(set) var startedAt: Date?
    public private(set) var endedAt: Date?

    private let validateSelectionUseCase: ValidateSelectionUseCase
    private let markWordFoundUseCase: MarkWordFoundUseCase

    public init(
        dayKey: DayKey,
        gridSize: Int,
        puzzle: Puzzle,
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>,
        startedAt: Date?,
        endedAt: Date?,
        validateSelectionUseCase: ValidateSelectionUseCase = ValidateSelectionUseCase(),
        markWordFoundUseCase: MarkWordFoundUseCase = MarkWordFoundUseCase()
    ) {
        self.dayKey = dayKey
        self.gridSize = gridSize
        self.puzzle = puzzle
        self.validateSelectionUseCase = validateSelectionUseCase
        self.markWordFoundUseCase = markWordFoundUseCase

        let normalizedWords = Set(foundWords.map(WordSearchNormalization.normalizedWord))
        self.foundWords = normalizedWords.intersection(puzzle.wordSet)

        self.solvedPositions = solvedPositions.filter { puzzle.grid.contains($0) }
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public var isCompleted: Bool {
        !puzzle.words.isEmpty && foundWords.count >= puzzle.words.count
    }

    @discardableResult
    public func startIfNeeded(now: Date = Date()) -> Bool {
        guard startedAt == nil, !isCompleted else { return false }
        startedAt = now
        return true
    }

    public func finalizeSelection(_ positions: [GridPosition], now: Date = Date()) -> DailyPuzzleSelectionOutcome {
        guard positions.count >= 2 else {
            return DailyPuzzleSelectionOutcome(kind: .ignored, completedPuzzleNow: false)
        }

        let validation = validateSelectionUseCase.execute(
            selection: Selection(positions: positions),
            puzzle: puzzle,
            foundWords: foundWords
        )

        guard let matchedWord = validation.matchedWord else {
            return DailyPuzzleSelectionOutcome(kind: .incorrect, completedPuzzleNow: false)
        }

        let session = Session(
            dayKey: dayKey,
            gridSize: gridSize,
            foundWords: foundWords,
            solvedPositions: solvedPositions,
            startedAt: startedAt,
            endedAt: endedAt
        )

        let updated = markWordFoundUseCase.execute(
            session: session,
            matchedWord: matchedWord,
            positions: validation.normalizedPath,
            now: now
        )

        foundWords = updated.foundWords
        solvedPositions = updated.solvedPositions
        startedAt = updated.startedAt

        let completedNow = isCompleted && endedAt == nil
        if completedNow {
            endedAt = now
        }

        return DailyPuzzleSelectionOutcome(
            kind: .correct(matchedWord: matchedWord),
            completedPuzzleNow: completedNow
        )
    }

    public func reset() {
        foundWords = []
        solvedPositions = []
        startedAt = nil
        endedAt = nil
    }
}
