import Foundation
import Observation
import Core

@Observable
@MainActor
public final class SettingsViewModel {
    public private(set) var model: SettingsUIModel

    private let core: CoreContainer

    public init(core: CoreContainer) {
        self.core = core
        self.model = Self.makeModel(from: core.loadSettingsUseCase.execute())
    }

    public func refresh() {
        model = Self.makeModel(from: core.loadSettingsUseCase.execute())
    }

    public func setGridSize(_ value: Int) {
        model.gridSize = min(max(value, WordSearchConfig.minGridSize), WordSearchConfig.maxGridSize)
    }

    public func makeSheetValues() -> SettingsSheetValues {
        SettingsSheetValues(
            gridSize: model.gridSize,
            appearanceMode: model.appearanceMode,
            wordHintMode: model.wordHintMode,
            dailyRefreshMinutes: model.dailyRefreshMinutes,
            enableCelebrations: model.enableCelebrations,
            enableHaptics: model.enableHaptics,
            enableSound: model.enableSound,
            celebrationIntensity: model.celebrationIntensity
        )
    }

    @discardableResult
    public func save(values: SettingsSheetValues) -> SettingsUIModel {
        var settings = core.loadSettingsUseCase.execute()
        settings.gridSize = PuzzleFactory.clampGridSize(values.gridSize)
        settings.appearanceMode = values.appearanceMode
        settings.wordHintMode = values.wordHintMode
        settings.dailyRefreshMinutes = DailyRefreshClock.clampMinutes(values.dailyRefreshMinutes)
        settings.enableCelebrations = values.enableCelebrations
        settings.enableHaptics = values.enableHaptics
        settings.enableSound = values.enableSound
        settings.celebrationIntensity = values.celebrationIntensity
        core.saveSettingsUseCase.execute(settings)

        let normalized = Self.makeModel(from: settings)
        model = normalized
        return normalized
    }

    public func save() {
        _ = save(values: makeSheetValues())
    }

    private static func makeModel(from settings: AppSettings) -> SettingsUIModel {
        SettingsUIModel(
            gridSize: settings.gridSize,
            appearanceMode: settings.appearanceMode,
            wordHintMode: settings.wordHintMode,
            dailyRefreshMinutes: settings.dailyRefreshMinutes,
            enableCelebrations: settings.enableCelebrations,
            enableHaptics: settings.enableHaptics,
            enableSound: settings.enableSound,
            celebrationIntensity: settings.celebrationIntensity
        )
    }
}
