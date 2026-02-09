import Foundation
import Core

public struct SettingsContainer {
    public let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
    }

    @MainActor
    public func makeViewModel() -> SettingsViewModel {
        SettingsViewModel(core: core)
    }
}
