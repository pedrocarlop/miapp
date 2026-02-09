import Foundation
import Combine
import Core
import FeatureDailyPuzzle
import FeatureHistory
import FeatureSettings

@MainActor
final class AppContainer: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    let core: CoreContainer
    let dailyPuzzle: DailyPuzzleContainer
    let history: HistoryContainer
    let settings: SettingsContainer

    init(core: CoreContainer) {
        self.core = core
        self.dailyPuzzle = DailyPuzzleContainer(core: core)
        self.history = HistoryContainer(core: core)
        self.settings = SettingsContainer(core: core)
    }

    static let live: AppContainer = {
        AppContainer(core: CoreBootstrap.shared)
    }()
}
