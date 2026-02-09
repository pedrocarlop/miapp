import Foundation

public struct SharedPositionDTO: Codable, Hashable, Sendable {
    public let r: Int
    public let c: Int

    public init(r: Int, c: Int) {
        self.r = r
        self.c = c
    }
}

public enum SharedFeedbackKindDTO: String, Codable, Sendable {
    case correct
    case incorrect
}

public struct SharedFeedbackDTO: Codable, Hashable, Sendable {
    public var kind: SharedFeedbackKindDTO
    public var positions: [SharedPositionDTO]
    public var expiresAt: Date

    public init(kind: SharedFeedbackKindDTO, positions: [SharedPositionDTO], expiresAt: Date) {
        self.kind = kind
        self.positions = positions
        self.expiresAt = expiresAt
    }
}

public struct SharedPuzzleStateDTO: Codable, Hashable, Sendable {
    public var grid: [[String]]
    public var words: [String]
    public var gridSize: Int
    public var anchor: SharedPositionDTO?
    public var foundWords: Set<String>
    public var solvedPositions: Set<SharedPositionDTO>
    public var puzzleIndex: Int
    public var isHelpVisible: Bool
    public var feedback: SharedFeedbackDTO?
    public var pendingWord: String?
    public var pendingSolvedPositions: Set<SharedPositionDTO>
    public var nextHintWord: String?
    public var nextHintExpiresAt: Date?

    public init(
        grid: [[String]],
        words: [String],
        gridSize: Int,
        anchor: SharedPositionDTO?,
        foundWords: Set<String>,
        solvedPositions: Set<SharedPositionDTO>,
        puzzleIndex: Int,
        isHelpVisible: Bool,
        feedback: SharedFeedbackDTO?,
        pendingWord: String?,
        pendingSolvedPositions: Set<SharedPositionDTO>,
        nextHintWord: String?,
        nextHintExpiresAt: Date?
    ) {
        self.grid = grid
        self.words = words
        self.gridSize = gridSize
        self.anchor = anchor
        self.foundWords = foundWords
        self.solvedPositions = solvedPositions
        self.puzzleIndex = puzzleIndex
        self.isHelpVisible = isHelpVisible
        self.feedback = feedback
        self.pendingWord = pendingWord
        self.pendingSolvedPositions = pendingSolvedPositions
        self.nextHintWord = nextHintWord
        self.nextHintExpiresAt = nextHintExpiresAt
    }

    private enum CodingKeys: String, CodingKey {
        case grid
        case words
        case gridSize
        case anchor
        case foundWords
        case solvedPositions
        case puzzleIndex
        case isHelpVisible
        case feedback
        case pendingWord
        case pendingSolvedPositions
        case nextHintWord
        case nextHintExpiresAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        grid = try container.decodeIfPresent([[String]].self, forKey: .grid) ?? []
        words = try container.decodeIfPresent([String].self, forKey: .words) ?? []
        let decodedSize = try container.decodeIfPresent(Int.self, forKey: .gridSize) ?? grid.count
        gridSize = PuzzleFactory.clampGridSize(decodedSize)
        anchor = try container.decodeIfPresent(SharedPositionDTO.self, forKey: .anchor)
        foundWords = try container.decodeIfPresent(Set<String>.self, forKey: .foundWords) ?? []
        solvedPositions = try container.decodeIfPresent(Set<SharedPositionDTO>.self, forKey: .solvedPositions) ?? []
        puzzleIndex = try container.decodeIfPresent(Int.self, forKey: .puzzleIndex) ?? 0
        isHelpVisible = try container.decodeIfPresent(Bool.self, forKey: .isHelpVisible) ?? false
        feedback = try container.decodeIfPresent(SharedFeedbackDTO.self, forKey: .feedback)
        pendingWord = try container.decodeIfPresent(String.self, forKey: .pendingWord)
        pendingSolvedPositions = try container.decodeIfPresent(Set<SharedPositionDTO>.self, forKey: .pendingSolvedPositions) ?? []
        nextHintWord = try container.decodeIfPresent(String.self, forKey: .nextHintWord)
        nextHintExpiresAt = try container.decodeIfPresent(Date.self, forKey: .nextHintExpiresAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(grid, forKey: .grid)
        try container.encode(words, forKey: .words)
        try container.encode(gridSize, forKey: .gridSize)
        try container.encodeIfPresent(anchor, forKey: .anchor)
        try container.encode(foundWords, forKey: .foundWords)
        try container.encode(solvedPositions, forKey: .solvedPositions)
        try container.encode(puzzleIndex, forKey: .puzzleIndex)
        try container.encode(isHelpVisible, forKey: .isHelpVisible)
        try container.encodeIfPresent(feedback, forKey: .feedback)
        try container.encodeIfPresent(pendingWord, forKey: .pendingWord)
        try container.encode(pendingSolvedPositions, forKey: .pendingSolvedPositions)
        try container.encodeIfPresent(nextHintWord, forKey: .nextHintWord)
        try container.encodeIfPresent(nextHintExpiresAt, forKey: .nextHintExpiresAt)
    }
}

public struct AppProgressPositionDTO: Codable, Hashable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

public struct AppProgressRecordDTO: Codable, Hashable, Sendable {
    public let dayOffset: Int
    public let gridSize: Int
    public let foundWords: [String]
    public let solvedPositions: [AppProgressPositionDTO]
    public let startedAt: TimeInterval?
    public let endedAt: TimeInterval?

    public init(
        dayOffset: Int,
        gridSize: Int,
        foundWords: [String],
        solvedPositions: [AppProgressPositionDTO],
        startedAt: TimeInterval?,
        endedAt: TimeInterval?
    ) {
        self.dayOffset = dayOffset
        self.gridSize = gridSize
        self.foundWords = foundWords
        self.solvedPositions = solvedPositions
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

public struct LegacyPositionDTO: Codable, Sendable {
    public let r: Int
    public let c: Int
}

public struct LegacySlotStateDTO: Codable, Sendable {
    public var grid: [[String]]
    public var words: [String]
    public var foundWords: [String]
    public var solvedPositions: [LegacyPositionDTO]
    public var puzzleIndex: Int
}

public struct LegacyPuzzleStateV1DTO: Codable, Sendable {
    public var grid: [[String]]
    public var words: [String]
    public var foundWords: Set<String>
}
