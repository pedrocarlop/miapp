import Foundation
import Core

public struct DailyPuzzleUIModel: Equatable, Sendable {
    public let dayOffset: Int
    public let title: String
    public let totalWords: Int
    public let foundWords: Int
    public let progress: Double

    public init(dayOffset: Int, title: String, totalWords: Int, foundWords: Int, progress: Double) {
        self.dayOffset = dayOffset
        self.title = title
        self.totalWords = totalWords
        self.foundWords = foundWords
        self.progress = progress
    }
}
