import Foundation
import Core

public struct HistoryContainer {
    public let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
    }

    @MainActor
    public func makeViewModel() -> HistorySummaryViewModel {
        HistorySummaryViewModel(core: core)
    }
}
