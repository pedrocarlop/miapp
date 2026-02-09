import Foundation
import Core

public enum DailyPuzzleUIMapper {
    public static func makeModel(dayKey: DayKey, puzzle: Puzzle, score: Score) -> DailyPuzzleUIModel {
        DailyPuzzleUIModel(
            dayOffset: dayKey.offset,
            title: "Sopa diaria",
            totalWords: score.totalWords,
            foundWords: score.foundWords,
            progress: score.percentage
        )
    }
}
