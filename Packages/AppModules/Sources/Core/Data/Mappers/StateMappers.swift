import Foundation

public enum StateMappers {
    public static func toDomain(_ dto: SharedPuzzleStateDTO) -> SharedPuzzleState {
        SharedPuzzleState(
            grid: dto.grid,
            words: dto.words,
            gridSize: dto.gridSize,
            anchor: dto.anchor.map(toDomain),
            foundWords: dto.foundWords,
            solvedPositions: Set(dto.solvedPositions.map(toDomain)),
            puzzleIndex: dto.puzzleIndex,
            isHelpVisible: dto.isHelpVisible,
            feedback: dto.feedback.map(toDomain),
            pendingWord: dto.pendingWord,
            pendingSolvedPositions: Set(dto.pendingSolvedPositions.map(toDomain)),
            nextHintWord: dto.nextHintWord,
            nextHintExpiresAt: dto.nextHintExpiresAt
        )
    }

    public static func toDTO(_ state: SharedPuzzleState) -> SharedPuzzleStateDTO {
        SharedPuzzleStateDTO(
            grid: state.grid,
            words: state.words,
            gridSize: state.gridSize,
            anchor: state.anchor.map(toDTO),
            foundWords: state.foundWords,
            solvedPositions: Set(state.solvedPositions.map(toDTO)),
            puzzleIndex: state.puzzleIndex,
            isHelpVisible: state.isHelpVisible,
            feedback: state.feedback.map(toDTO),
            pendingWord: state.pendingWord,
            pendingSolvedPositions: Set(state.pendingSolvedPositions.map(toDTO)),
            nextHintWord: state.nextHintWord,
            nextHintExpiresAt: state.nextHintExpiresAt
        )
    }

    public static func toDomain(_ dto: AppProgressRecordDTO) -> AppProgressRecord {
        AppProgressRecord(
            dayOffset: dto.dayOffset,
            gridSize: dto.gridSize,
            foundWords: dto.foundWords,
            solvedPositions: dto.solvedPositions.map(toDomain),
            startedAt: dto.startedAt,
            endedAt: dto.endedAt
        )
    }

    public static func toDTO(_ model: AppProgressRecord) -> AppProgressRecordDTO {
        AppProgressRecordDTO(
            dayOffset: model.dayOffset,
            gridSize: model.gridSize,
            foundWords: model.foundWords,
            solvedPositions: model.solvedPositions.map(toDTO),
            startedAt: model.startedAt,
            endedAt: model.endedAt
        )
    }

    public static func toDomain(_ dto: SharedPositionDTO) -> GridPosition {
        GridPosition(row: dto.r, col: dto.c)
    }

    public static func toDTO(_ position: GridPosition) -> SharedPositionDTO {
        SharedPositionDTO(r: position.row, c: position.col)
    }

    public static func toDomain(_ dto: SharedFeedbackDTO) -> SelectionFeedback {
        SelectionFeedback(
            kind: dto.kind == .correct ? .correct : .incorrect,
            positions: dto.positions.map(toDomain),
            expiresAt: dto.expiresAt
        )
    }

    public static func toDTO(_ feedback: SelectionFeedback) -> SharedFeedbackDTO {
        SharedFeedbackDTO(
            kind: feedback.kind == .correct ? .correct : .incorrect,
            positions: feedback.positions.map(toDTO),
            expiresAt: feedback.expiresAt
        )
    }

    public static func toDomain(_ dto: AppProgressPositionDTO) -> GridPosition {
        GridPosition(row: dto.row, col: dto.col)
    }

    public static func toDTO(_ position: GridPosition) -> AppProgressPositionDTO {
        AppProgressPositionDTO(row: position.row, col: position.col)
    }
}
