import Foundation
import Core

public struct DailyPuzzleContainer {
    public let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
    }

    @MainActor
    public func makeRootViewModel() -> DailyPuzzleHomeViewModel {
        DailyPuzzleHomeViewModel(container: core)
    }

    @MainActor
    public func makeHomeScreenViewModel(initialGridSize: Int) -> DailyPuzzleHomeScreenViewModel {
        DailyPuzzleHomeScreenViewModel(
            core: core,
            preferredGridSize: initialGridSize
        )
    }
}
