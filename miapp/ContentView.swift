//
//  ContentView.swift
//  miapp
//
//  Created by Pedro Carrasco lopez brea on 8/2/26.
//

import SwiftUI
import UIKit
import WidgetKit
import Core
import DesignSystem
import FeatureSettings
import FeatureHistory
import FeatureDailyPuzzle

private struct HostPresentedGame: Identifiable, Equatable {
    let id: Int
}

private enum HostAccentPalette {
    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor { trait in
                trait.userInterfaceStyle == .dark ? dark : light
            }
        )
    }

    static let completedOrangeGradient = LinearGradient(
        colors: [
            adaptiveColor(
                light: UIColor(red: 1.0, green: 0.62, blue: 0.22, alpha: 1),
                dark: UIColor(red: 0.94, green: 0.52, blue: 0.16, alpha: 1)
            ),
            adaptiveColor(
                light: UIColor(red: 0.98, green: 0.44, blue: 0.13, alpha: 1),
                dark: UIColor(red: 0.80, green: 0.34, blue: 0.10, alpha: 1)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let streakBlueGradient = LinearGradient(
        colors: [
            adaptiveColor(
                light: UIColor(red: 0.22, green: 0.55, blue: 1.0, alpha: 1),
                dark: UIColor(red: 0.36, green: 0.64, blue: 1.0, alpha: 1)
            ),
            adaptiveColor(
                light: UIColor(red: 0.12, green: 0.34, blue: 0.92, alpha: 1),
                dark: UIColor(red: 0.22, green: 0.46, blue: 0.96, alpha: 1)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private enum HomePresentedSheet: Identifiable {
    case settings
    case counter(HistoryCounterInfoKind)

    var id: String {
        switch self {
        case .settings:
            return "settings"
        case .counter(let info):
            return "counter-\(info.id)"
        }
    }
}

private struct SoftGlowBackground: View {
    var body: some View {
        ColorTokens.backgroundPrimary
            .ignoresSafeArea()
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let container: AppContainer
    private var core: CoreContainer { container.core }

    @State private var presentedSheet: HomePresentedSheet?
    @State private var presentedGame: HostPresentedGame?
    @State private var launchingCardOffset: Int?
    @State private var settingsViewModel: SettingsViewModel
    @State private var historyViewModel: HistorySummaryViewModel
    @State private var dailyPuzzleHomeViewModel: DailyPuzzleHomeScreenViewModel

    @MainActor
    init(container: AppContainer) {
        self.container = container
        let settingsViewModel = container.settings.makeViewModel()
        let initialGridSize = settingsViewModel.model.gridSize

        _settingsViewModel = State(initialValue: settingsViewModel)
        _historyViewModel = State(initialValue: container.history.makeViewModel())
        _dailyPuzzleHomeViewModel = State(
            initialValue: container.dailyPuzzle.makeHomeScreenViewModel(
                initialGridSize: initialGridSize
            )
        )
    }

    private var todayOffset: Int {
        dailyPuzzleHomeViewModel.todayOffset
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoftGlowBackground()

                GeometryReader { geometry in
                    let verticalInset: CGFloat = 40
                    let interSectionSpacing: CGFloat = 40
                    let dayCarouselHeight: CGFloat = 106
                    let cardWidth = min(geometry.size.width * 0.80, 450)
                    let sidePadding = max((geometry.size.width - cardWidth) / 2, 10)
                    let availableCardHeight = geometry.size.height - dayCarouselHeight - interSectionSpacing - (verticalInset * 2)
                    let cardHeight = min(max(availableCardHeight, 260), 620)
                    let cardSelection = Binding<Int?>(
                        get: {
                            let current = dailyPuzzleHomeViewModel.selectedOffset ?? todayOffset
                            return dailyPuzzleHomeViewModel.carouselOffsets.contains(current) ? current : nil
                        },
                        set: { dailyPuzzleHomeViewModel.setSelectedOffset($0) }
                    )

                    VStack(spacing: interSectionSpacing) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 14) {
                                ForEach(dailyPuzzleHomeViewModel.carouselOffsets, id: \.self) { offset in
                                    let date = dailyPuzzleHomeViewModel.puzzleDate(for: offset)
                                    let puzzle = dailyPuzzleHomeViewModel.puzzleForOffset(
                                        offset,
                                        preferredGridSize: settingsViewModel.model.gridSize
                                    )
                                    let progress = dailyPuzzleHomeViewModel.progressForOffset(
                                        offset,
                                        puzzle: puzzle,
                                        preferredGridSize: settingsViewModel.model.gridSize
                                    )
                                    let isLocked = dailyPuzzleHomeViewModel.isLocked(offset: offset)
                                    let hoursLeft = dailyPuzzleHomeViewModel.hoursUntilAvailable(for: offset)

                                    DailyPuzzleChallengeCardView(
                                        date: date,
                                        puzzleNumber: puzzle.number,
                                        grid: puzzle.grid.letters,
                                        words: puzzle.words.map(\.text),
                                        foundWords: progress.foundWords,
                                        solvedPositions: progress.solvedPositions,
                                        isLocked: isLocked,
                                        hoursUntilAvailable: hoursLeft,
                                        isLaunching: launchingCardOffset == offset
                                    ) {
                                        handleChallengeCardTap(offset: offset)
                                    }
                                    .frame(width: cardWidth, height: cardHeight)
                                    .scaleEffect(launchingCardOffset == offset ? 1.10 : 1)
                                    .opacity(launchingCardOffset == nil || launchingCardOffset == offset ? 1 : 0.45)
                                    .zIndex(launchingCardOffset == offset ? 5 : 0)
                                    .id(offset)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, sidePadding)
                        }
                        .frame(height: cardHeight)
                        .scrollClipDisabled(true)
                        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                        .scrollPosition(id: cardSelection, anchor: .center)

                        DailyPuzzleDayCarouselView(
                            offsets: dailyPuzzleHomeViewModel.carouselOffsets,
                            selectedOffset: Binding(
                                get: { dailyPuzzleHomeViewModel.selectedOffset },
                                set: { dailyPuzzleHomeViewModel.setSelectedOffset($0) }
                            ),
                            todayOffset: todayOffset,
                            unlockedOffsets: dailyPuzzleHomeViewModel.easterUnlockedOffsets,
                            dateForOffset: { dailyPuzzleHomeViewModel.puzzleDate(for: $0) },
                            progressForOffset: {
                                dailyPuzzleHomeViewModel.progressFraction(
                                    for: $0,
                                    preferredGridSize: settingsViewModel.model.gridSize
                                )
                            }
                        ) { offset in
                            dailyPuzzleHomeViewModel.hoursUntilAvailable(for: offset)
                        }
                        .frame(height: dayCarouselHeight)
                        .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, verticalInset)
                    .padding(.bottom, verticalInset)
                }

                if let selection = presentedGame {
                    gameOverlay(for: selection.id)
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                        .zIndex(50)
                }

            }
            .animation(.easeInOut(duration: 0.24), value: presentedGame)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if presentedGame == nil {
                    ToolbarItem(placement: .principal) {
                        Text("Sopa diaria")
                            .font(TypographyTokens.titleSmall)
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HistoryNavCounterView(
                            value: historyViewModel.model.completedCount,
                            systemImage: "checkmark.seal.fill",
                            iconGradient: HostAccentPalette.streakBlueGradient,
                            accessibilityLabel: "Retos completados \(historyViewModel.model.completedCount)",
                            accessibilityHint: "Pulsa para saber que mide este contador"
                        ) {
                            presentedSheet = .counter(.completedPuzzles)
                        }
                        HistoryNavCounterView(
                            value: historyViewModel.model.currentStreak,
                            systemImage: "flame.fill",
                            iconGradient: HostAccentPalette.completedOrangeGradient,
                            accessibilityLabel: "Racha actual \(historyViewModel.model.currentStreak)",
                            accessibilityHint: "Pulsa para saber que mide este contador"
                        ) {
                            presentedSheet = .counter(.streak)
                        }
                        Button {
                            presentedSheet = .settings
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(ColorTokens.textPrimary)
                        }
                        .accessibilityLabel("Abrir ajustes")
                    }
                }
            }
            .onAppear {
                settingsViewModel.refresh()
                refreshDailyPuzzleState()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                settingsViewModel.refresh()
                refreshDailyPuzzleState()
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsSheetView(
                        values: settingsViewModel.makeSheetValues()
                    ) { updated in
                        settingsViewModel.save(values: updated)
                        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConfig.widgetKind)
                        refreshDailyPuzzleState()
                    }
                case .counter(let info):
                    HistoryCounterInfoSheetView(
                        core: core,
                        info: info
                    )
                }
            }
        }
        .preferredColorScheme(settingsViewModel.model.appearanceMode.colorScheme)
        .font(TypographyTokens.body)
    }

    private func refreshDailyPuzzleState() {
        dailyPuzzleHomeViewModel.refresh(preferredGridSize: settingsViewModel.model.gridSize)
        historyViewModel.refresh()
    }

    @ViewBuilder
    private func gameOverlay(for offset: Int) -> some View {
        let puzzle = dailyPuzzleHomeViewModel.puzzleForOffset(
            offset,
            preferredGridSize: settingsViewModel.model.gridSize
        )
        let record = dailyPuzzleHomeViewModel.initialProgressRecord(
            for: offset,
            preferredGridSize: settingsViewModel.model.gridSize
        )
        let puzzleGridSize = puzzle.grid.size
        let title = HostDateFormatter.monthDay(for: dailyPuzzleHomeViewModel.puzzleDate(for: offset))
        let sharedSync = dailyPuzzleHomeViewModel.sharedPuzzleIndex(for: offset).map {
            DailyPuzzleSharedSyncContext(puzzleIndex: $0)
        }

        ZStack {
            ColorTokens.surfacePrimary
                .ignoresSafeArea()

            DailyPuzzleGameScreenView(
                core: core,
                dayOffset: offset,
                todayOffset: todayOffset,
                navigationTitle: title,
                puzzle: puzzle,
                gridSize: puzzleGridSize,
                wordHintMode: settingsViewModel.model.wordHintMode,
                initialProgress: record,
                sharedSync: sharedSync,
                onProgressUpdate: {
                    refreshDailyPuzzleState()
                },
                onClose: {
                    closePresentedGame()
                },
                celebrationPreferencesProvider: {
                    currentCelebrationPreferences()
                },
                onWordFeedback: { preferences in
                    playWordFeedback(preferences)
                },
                onCompletionFeedback: { preferences in
                    playCompletionFeedback(preferences)
                },
                onSharedStateMutation: {
                    WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConfig.widgetKind)
                }
            )
        }
    }

    private func closePresentedGame() {
        withAnimation(.easeInOut(duration: 0.22)) {
            presentedGame = nil
        }
    }

    private func presentGameFromCard(offset: Int) {
        guard presentedGame == nil else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            launchingCardOffset = offset
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 110_000_000)
            withAnimation(.easeInOut(duration: 0.22)) {
                presentedGame = HostPresentedGame(id: offset)
            }
            try? await Task.sleep(nanoseconds: 170_000_000)
            if launchingCardOffset == offset {
                launchingCardOffset = nil
            }
        }
    }

    private func handleChallengeCardTap(offset: Int) {
        switch dailyPuzzleHomeViewModel.handleChallengeCardTap(offset: offset) {
        case .openGame:
            presentGameFromCard(offset: offset)
        case .unlocked, .noAction:
            break
        }
    }

    private func currentCelebrationPreferences() -> DailyPuzzleCelebrationPreferences {
        let settings = core.loadSettingsUseCase.execute()
        return DailyPuzzleCelebrationPreferences(
            enableCelebrations: settings.enableCelebrations,
            enableHaptics: settings.enableHaptics,
            enableSound: settings.enableSound,
            intensity: settings.celebrationIntensity
        )
    }

    private func playWordFeedback(_ preferences: DailyPuzzleCelebrationPreferences) {
        if preferences.enableHaptics {
            HostHaptics.wordSuccess()
        }
        if preferences.enableSound {
            HostSoundPlayer.play(.word)
        }
    }

    private func playCompletionFeedback(_ preferences: DailyPuzzleCelebrationPreferences) {
        if preferences.enableHaptics {
            HostHaptics.completionSuccess()
        }
        if preferences.enableSound {
            HostSoundPlayer.play(.completion)
        }
    }

}

private extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#Preview {
    ContentView(container: AppContainer.live)
}
