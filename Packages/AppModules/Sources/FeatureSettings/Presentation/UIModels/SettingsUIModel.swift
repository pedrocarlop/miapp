import Foundation
import Core

public struct SettingsUIModel: Equatable, Sendable {
    public var gridSize: Int
    public var appearanceMode: AppearanceMode
    public var wordHintMode: WordHintMode
    public var dailyRefreshMinutes: Int
    public var enableCelebrations: Bool
    public var enableHaptics: Bool
    public var enableSound: Bool
    public var celebrationIntensity: CelebrationIntensity

    public init(
        gridSize: Int,
        appearanceMode: AppearanceMode,
        wordHintMode: WordHintMode,
        dailyRefreshMinutes: Int,
        enableCelebrations: Bool,
        enableHaptics: Bool,
        enableSound: Bool,
        celebrationIntensity: CelebrationIntensity
    ) {
        self.gridSize = gridSize
        self.appearanceMode = appearanceMode
        self.wordHintMode = wordHintMode
        self.dailyRefreshMinutes = dailyRefreshMinutes
        self.enableCelebrations = enableCelebrations
        self.enableHaptics = enableHaptics
        self.enableSound = enableSound
        self.celebrationIntensity = celebrationIntensity
    }
}
