import Foundation
import Observation
import Core

@Observable
@MainActor
public final class DailyPuzzleHomeViewModel {
    public private(set) var model: DailyPuzzleUIModel?
    public private(set) var currentDayKey: DayKey = DayKey(offset: 0)

    private let container: CoreContainer

    public init(container: CoreContainer) {
        self.container = container
    }

    public func refresh(now: Date = Date()) {
        let settings = container.loadSettingsUseCase.execute()
        let dayKey = container.todayDayKey(now: now)
        let puzzle = container.getDailyPuzzleUseCase.execute(dayKey: dayKey, gridSize: settings.gridSize)
        let session = container.startDailySessionUseCase.execute(dayKey: dayKey, gridSize: settings.gridSize)
        let score = container.computeScoreUseCase.execute(session: session, puzzle: puzzle)

        currentDayKey = dayKey
        model = DailyPuzzleUIMapper.makeModel(dayKey: dayKey, puzzle: puzzle, score: score)
    }
}
