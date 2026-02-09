import Foundation
import Core

@available(iOS 17.0, *)
final class WordSearchWidgetContainer {
    static let shared = WordSearchWidgetContainer(core: CoreContainer.live())

    private let core: CoreContainer

    init(core: CoreContainer) {
        self.core = core
    }

    func settings() -> AppSettings {
        core.loadSettingsUseCase.execute()
    }

    func loadState(now: Date) -> SharedPuzzleState {
        let settings = self.settings()
        return core.getSharedPuzzleStateUseCase.execute(
            now: now,
            preferredGridSize: settings.gridSize
        )
    }

    @discardableResult
    func applyTap(row: Int, col: Int, now: Date) -> SharedPuzzleTapResult {
        let settings = self.settings()
        return core.applySharedTapUseCase.execute(
            row: row,
            col: col,
            now: now,
            preferredGridSize: settings.gridSize
        )
    }

    @discardableResult
    func toggleHelp(now: Date) -> SharedPuzzleState {
        let settings = self.settings()
        return core.toggleSharedHelpUseCase.execute(
            now: now,
            preferredGridSize: settings.gridSize
        )
    }

    @discardableResult
    func dismissHint(now: Date) -> SharedPuzzleState {
        let settings = self.settings()
        return core.dismissSharedHintUseCase.execute(
            now: now,
            preferredGridSize: settings.gridSize
        )
    }
}
