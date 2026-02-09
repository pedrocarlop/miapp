import Foundation

public final class LocalSettingsRepository: SettingsRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public func load() -> AppSettings {
        let storedGrid = store.integer(forKey: WordSearchConfig.gridSizeKey)
        let gridSize: Int
        if storedGrid == 0 {
            gridSize = WordSearchConfig.minGridSize
            store.set(gridSize, forKey: WordSearchConfig.gridSizeKey)
        } else {
            gridSize = PuzzleFactory.clampGridSize(storedGrid)
            if gridSize != storedGrid {
                store.set(gridSize, forKey: WordSearchConfig.gridSizeKey)
            }
        }

        let appearanceMode = AppearanceMode(rawValue: store.string(forKey: WordSearchConfig.appearanceModeKey) ?? "") ?? .system
        let wordHintMode = WordHintMode(rawValue: store.string(forKey: WordSearchConfig.wordHintModeKey) ?? "") ?? .word

        let storedMinutes = store.object(forKey: WordSearchConfig.dailyRefreshMinutesKey) as? Int
        let dailyRefreshMinutes: Int
        if let storedMinutes {
            dailyRefreshMinutes = DailyRefreshClock.clampMinutes(storedMinutes)
            if dailyRefreshMinutes != storedMinutes {
                store.set(dailyRefreshMinutes, forKey: WordSearchConfig.dailyRefreshMinutesKey)
            }
        } else {
            dailyRefreshMinutes = WordSearchConfig.defaultDailyRefreshMinutes
            store.set(dailyRefreshMinutes, forKey: WordSearchConfig.dailyRefreshMinutesKey)
        }

        let enableCelebrations = store.object(forKey: WordSearchConfig.enableCelebrationsKey) as? Bool ?? true
        let enableHaptics = store.object(forKey: WordSearchConfig.enableHapticsKey) as? Bool ?? true
        let enableSound = store.object(forKey: WordSearchConfig.enableSoundKey) as? Bool ?? false
        let intensityRaw = store.string(forKey: WordSearchConfig.intensityKey) ?? CelebrationIntensity.medium.rawValue
        let celebrationIntensity = CelebrationIntensity(rawValue: intensityRaw) ?? .medium

        return AppSettings(
            gridSize: gridSize,
            appearanceMode: appearanceMode,
            wordHintMode: wordHintMode,
            dailyRefreshMinutes: dailyRefreshMinutes,
            enableCelebrations: enableCelebrations,
            enableHaptics: enableHaptics,
            enableSound: enableSound,
            celebrationIntensity: celebrationIntensity
        )
    }

    public func save(_ settings: AppSettings) {
        store.set(PuzzleFactory.clampGridSize(settings.gridSize), forKey: WordSearchConfig.gridSizeKey)
        store.set(settings.appearanceMode.rawValue, forKey: WordSearchConfig.appearanceModeKey)
        store.set(settings.wordHintMode.rawValue, forKey: WordSearchConfig.wordHintModeKey)
        store.set(DailyRefreshClock.clampMinutes(settings.dailyRefreshMinutes), forKey: WordSearchConfig.dailyRefreshMinutesKey)
        store.set(settings.enableCelebrations, forKey: WordSearchConfig.enableCelebrationsKey)
        store.set(settings.enableHaptics, forKey: WordSearchConfig.enableHapticsKey)
        store.set(settings.enableSound, forKey: WordSearchConfig.enableSoundKey)
        store.set(settings.celebrationIntensity.rawValue, forKey: WordSearchConfig.intensityKey)
    }
}
