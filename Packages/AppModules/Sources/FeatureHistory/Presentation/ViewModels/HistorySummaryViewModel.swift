import Foundation
import Observation
import Core

@Observable
@MainActor
public final class HistorySummaryViewModel {
    public private(set) var model = HistorySummaryUIModel(completedCount: 0, currentStreak: 0)

    private let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
    }

    public func refresh(now: Date = Date()) {
        let completed = core.getCompletedOffsetsUseCase.execute().count
        let today = core.todayDayKey(now: now)
        let streak = core.updateStreakUseCase.refresh(todayKey: today)
        model = HistorySummaryUIModel(completedCount: completed, currentStreak: streak.current)
    }
}
