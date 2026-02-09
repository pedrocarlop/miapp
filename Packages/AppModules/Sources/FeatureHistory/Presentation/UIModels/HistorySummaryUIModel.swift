import Foundation

public struct HistorySummaryUIModel: Equatable, Sendable {
    public let completedCount: Int
    public let currentStreak: Int

    public init(completedCount: Int, currentStreak: Int) {
        self.completedCount = completedCount
        self.currentStreak = currentStreak
    }
}
