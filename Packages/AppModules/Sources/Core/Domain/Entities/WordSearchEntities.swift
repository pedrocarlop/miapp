import Foundation

public struct DayKey: Hashable, Codable, Comparable, Sendable {
    public let offset: Int

    public init(offset: Int) {
        self.offset = max(0, offset)
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        lhs.offset < rhs.offset
    }
}

public struct WordId: Hashable, Codable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = WordSearchNormalization.normalizedWord(rawValue)
    }
}

public struct Word: Hashable, Codable, Sendable {
    public let id: WordId
    public let text: String

    public init(text: String) {
        let normalized = WordSearchNormalization.normalizedWord(text)
        self.id = WordId(normalized)
        self.text = normalized
    }
}

public struct GridPosition: Hashable, Codable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    public init(r: Int, c: Int) {
        self.row = r
        self.col = c
    }

    public var r: Int { row }
    public var c: Int { col }
}

public struct Grid: Hashable, Codable, Sendable {
    public let letters: [[String]]

    public init(letters: [[String]]) {
        self.letters = letters.map { row in
            row.map { WordSearchNormalization.normalizedWord($0) }
        }
    }

    public var rowCount: Int {
        letters.count
    }

    public var columnCount: Int {
        letters.first?.count ?? 0
    }

    public var size: Int {
        max(rowCount, columnCount)
    }

    public var isSquare: Bool {
        !letters.isEmpty && letters.allSatisfy { $0.count == letters.count }
    }

    public func contains(_ position: GridPosition) -> Bool {
        position.row >= 0 && position.col >= 0
        && position.row < rowCount
        && position.col < columnCount
    }

    public func word(at positions: [GridPosition]) -> String? {
        guard !positions.isEmpty else { return nil }
        var lettersInPath: [String] = []
        lettersInPath.reserveCapacity(positions.count)

        for position in positions {
            guard contains(position) else { return nil }
            lettersInPath.append(letters[position.row][position.col])
        }

        return lettersInPath.joined()
    }
}

public struct Puzzle: Hashable, Codable, Sendable {
    public let number: Int
    public let dayKey: DayKey
    public let grid: Grid
    public let words: [Word]

    public init(number: Int, dayKey: DayKey, grid: Grid, words: [Word]) {
        self.number = number
        self.dayKey = dayKey
        self.grid = grid
        self.words = words
    }

    public var wordSet: Set<String> {
        Set(words.map(\.text))
    }

    public var isEmpty: Bool {
        words.isEmpty || grid.letters.isEmpty
    }
}

public struct Selection: Hashable, Codable, Sendable {
    public let positions: [GridPosition]

    public init(positions: [GridPosition]) {
        self.positions = positions
    }
}

public struct Session: Hashable, Codable, Sendable {
    public var dayKey: DayKey
    public var gridSize: Int
    public var foundWords: Set<String>
    public var solvedPositions: Set<GridPosition>
    public var startedAt: Date?
    public var endedAt: Date?

    public init(
        dayKey: DayKey,
        gridSize: Int,
        foundWords: Set<String> = [],
        solvedPositions: Set<GridPosition> = [],
        startedAt: Date? = nil,
        endedAt: Date? = nil
    ) {
        self.dayKey = dayKey
        self.gridSize = gridSize
        self.foundWords = Set(foundWords.map(WordSearchNormalization.normalizedWord))
        self.solvedPositions = solvedPositions
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

public struct Score: Hashable, Codable, Sendable {
    public let foundWords: Int
    public let totalWords: Int
    public let percentage: Double

    public init(foundWords: Int, totalWords: Int) {
        self.foundWords = max(0, foundWords)
        self.totalWords = max(0, totalWords)
        if totalWords == 0 {
            self.percentage = 0
        } else {
            self.percentage = min(max(Double(foundWords) / Double(totalWords), 0), 1)
        }
    }
}

public struct Streak: Hashable, Codable, Sendable {
    public var current: Int
    public var lastCompletedOffset: Int

    public init(current: Int, lastCompletedOffset: Int) {
        self.current = max(0, current)
        self.lastCompletedOffset = lastCompletedOffset
    }

    public static let empty = Streak(current: 0, lastCompletedOffset: -1)
}

public struct HintState: Hashable, Codable, Sendable {
    public var available: Int
    public var lastRechargeOffset: Int
    public var lastRewardOffset: Int

    public init(available: Int, lastRechargeOffset: Int, lastRewardOffset: Int) {
        self.available = max(0, available)
        self.lastRechargeOffset = lastRechargeOffset
        self.lastRewardOffset = lastRewardOffset
    }

    public static let empty = HintState(available: 0, lastRechargeOffset: -1, lastRewardOffset: -1)
}

public enum AppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark
}

public enum WordHintMode: String, CaseIterable, Codable, Sendable {
    case word
    case definition
}

public struct AppSettings: Hashable, Codable, Sendable {
    public var gridSize: Int
    public var appearanceMode: AppearanceMode
    public var wordHintMode: WordHintMode
    public var dailyRefreshMinutes: Int
    public var enableCelebrations: Bool
    public var enableHaptics: Bool
    public var enableSound: Bool
    public var celebrationIntensity: CelebrationIntensity

    public init(
        gridSize: Int,
        appearanceMode: AppearanceMode,
        wordHintMode: WordHintMode,
        dailyRefreshMinutes: Int,
        enableCelebrations: Bool,
        enableHaptics: Bool,
        enableSound: Bool,
        celebrationIntensity: CelebrationIntensity
    ) {
        self.gridSize = gridSize
        self.appearanceMode = appearanceMode
        self.wordHintMode = wordHintMode
        self.dailyRefreshMinutes = dailyRefreshMinutes
        self.enableCelebrations = enableCelebrations
        self.enableHaptics = enableHaptics
        self.enableSound = enableSound
        self.celebrationIntensity = celebrationIntensity
    }

    public static let `default` = AppSettings(
        gridSize: 7,
        appearanceMode: .system,
        wordHintMode: .word,
        dailyRefreshMinutes: 9 * 60,
        enableCelebrations: true,
        enableHaptics: true,
        enableSound: false,
        celebrationIntensity: .medium
    )
}

public enum CelebrationIntensity: String, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high

    public var particleBirthRate: Float {
        switch self {
        case .low: return 160
        case .medium: return 220
        case .high: return 300
        }
    }
}

public enum SelectionFeedbackKind: String, Codable, Sendable {
    case correct
    case incorrect
}

public struct SelectionFeedback: Hashable, Codable, Sendable {
    public var kind: SelectionFeedbackKind
    public var positions: [GridPosition]
    public var expiresAt: Date

    public init(kind: SelectionFeedbackKind, positions: [GridPosition], expiresAt: Date) {
        self.kind = kind
        self.positions = positions
        self.expiresAt = expiresAt
    }
}

public struct SharedPuzzleState: Hashable, Codable, Sendable {
    public var grid: [[String]]
    public var words: [String]
    public var gridSize: Int
    public var anchor: GridPosition?
    public var foundWords: Set<String>
    public var solvedPositions: Set<GridPosition>
    public var puzzleIndex: Int
    public var isHelpVisible: Bool
    public var feedback: SelectionFeedback?
    public var pendingWord: String?
    public var pendingSolvedPositions: Set<GridPosition>
    public var nextHintWord: String?
    public var nextHintExpiresAt: Date?

    public init(
        grid: [[String]],
        words: [String],
        gridSize: Int,
        anchor: GridPosition?,
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>,
        puzzleIndex: Int,
        isHelpVisible: Bool,
        feedback: SelectionFeedback?,
        pendingWord: String?,
        pendingSolvedPositions: Set<GridPosition>,
        nextHintWord: String?,
        nextHintExpiresAt: Date?
    ) {
        self.grid = grid.map { row in row.map(WordSearchNormalization.normalizedWord) }
        self.words = words.map(WordSearchNormalization.normalizedWord)
        self.gridSize = gridSize
        self.anchor = anchor
        self.foundWords = Set(foundWords.map(WordSearchNormalization.normalizedWord))
        self.solvedPositions = solvedPositions
        self.puzzleIndex = puzzleIndex
        self.isHelpVisible = isHelpVisible
        self.feedback = feedback
        self.pendingWord = pendingWord.map(WordSearchNormalization.normalizedWord)
        self.pendingSolvedPositions = pendingSolvedPositions
        self.nextHintWord = nextHintWord.map(WordSearchNormalization.normalizedWord)
        self.nextHintExpiresAt = nextHintExpiresAt
    }

    public var isCompleted: Bool {
        let expected = Set(words.map(WordSearchNormalization.normalizedWord))
        let found = Set(foundWords.map(WordSearchNormalization.normalizedWord))
        return !expected.isEmpty && expected.isSubset(of: found)
    }
}

public struct AppProgressRecord: Hashable, Codable, Sendable {
    public let dayOffset: Int
    public let gridSize: Int
    public let foundWords: [String]
    public let solvedPositions: [GridPosition]
    public let startedAt: TimeInterval?
    public let endedAt: TimeInterval?

    public init(
        dayOffset: Int,
        gridSize: Int,
        foundWords: [String],
        solvedPositions: [GridPosition],
        startedAt: TimeInterval?,
        endedAt: TimeInterval?
    ) {
        self.dayOffset = dayOffset
        self.gridSize = gridSize
        self.foundWords = foundWords.map(WordSearchNormalization.normalizedWord)
        self.solvedPositions = solvedPositions
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public var startedDate: Date? {
        startedAt.map { Date(timeIntervalSince1970: $0) }
    }

    public var endedDate: Date? {
        endedAt.map { Date(timeIntervalSince1970: $0) }
    }

    public func asSession() -> Session {
        Session(
            dayKey: DayKey(offset: dayOffset),
            gridSize: gridSize,
            foundWords: Set(foundWords),
            solvedPositions: Set(solvedPositions),
            startedAt: startedDate,
            endedAt: endedDate
        )
    }
}

public struct SharedPuzzleTapResult: Hashable, Sendable {
    public let state: SharedPuzzleState
    public let didChange: Bool

    public init(state: SharedPuzzleState, didChange: Bool) {
        self.state = state
        self.didChange = didChange
    }
}
