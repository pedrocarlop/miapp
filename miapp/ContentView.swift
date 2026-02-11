/*
 BEGINNER NOTES (AUTO):
 - Archivo: miapp/ContentView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: HostPresentedGame,HomePresentedSheet ContentView
 - Funciones clave en este archivo: refreshDailyPuzzleState,gameOverlay reloadWidgetTimeline,closePresentedGame presentGameFromCard,handleChallengeCardTap
 - Como leerlo sin experiencia:
   1) Busca primero los tipos clave para entender 'quien vive aqui'.
   2) Revisa propiedades (let/var): indican que datos mantiene cada tipo.
   3) Sigue funciones publicas: son la puerta de entrada para otras capas.
   4) Luego mira funciones privadas: implementan detalles internos paso a paso.
   5) Si ves guard/if/switch, son decisiones que controlan el flujo.
 - Recordatorio rapido de sintaxis:
   - let = valor fijo; var = valor que puede cambiar.
   - guard = valida pronto; si falla, sale de la funcion.
   - return = devuelve un resultado y cierra esa funcion.
*/

//
//  ContentView.swift
//  miapp
//
//  Created by Pedro Carrasco lopez brea on 8/2/26.
//

import SwiftUI
import WidgetKit
import Core
import DesignSystem
import FeatureSettings
import FeatureHistory
import FeatureDailyPuzzle

private struct HostPresentedGame: Identifiable, Equatable {
    let id: Int
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

struct ContentView: View {
    private enum Constants {
        static let closeGameAnimationDuration: Double = 0.22
        static let launchCardAnimationDuration: Double = 0.18
        static let presentGameAnimationDuration: Double = 0.22
        static let launchCardSettleDelayNanos: UInt64 = 110_000_000
        static let launchCardCleanupDelayNanos: UInt64 = 170_000_000
        static let minimumHomeRefreshInterval: TimeInterval = 0.75
    }

    @Environment(\.scenePhase) private var scenePhase
    private let container: AppContainer
    private var core: CoreContainer { container.core }

    @State private var presentedSheet: HomePresentedSheet?
    @State private var presentedGame: HostPresentedGame?
    @State private var launchingCardOffset: Int?
    @State private var presentGameTask: Task<Void, Never>?
    @State private var settingsViewModel: SettingsViewModel
    @State private var historyViewModel: HistorySummaryViewModel
    @State private var dailyPuzzleHomeViewModel: DailyPuzzleHomeScreenViewModel
    @State private var lastHomeRefreshAt: Date = .distantPast
    @Namespace private var toolbarActionTransitionNamespace

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
                DSPageBackgroundView()

                HomeScreenLayout(
                    challengeCards: dailyPuzzleHomeViewModel.challengeCards,
                    carouselOffsets: dailyPuzzleHomeViewModel.carouselOffsets,
                    selectedOffset: Binding(
                        get: { dailyPuzzleHomeViewModel.selectedOffset },
                        set: { dailyPuzzleHomeViewModel.setSelectedOffset($0) }
                    ),
                    todayOffset: todayOffset,
                    unlockedOffsets: dailyPuzzleHomeViewModel.easterUnlockedOffsets,
                    launchingCardOffset: launchingCardOffset,
                    onCardTap: handleChallengeCardTap(offset:),
                    dateForOffset: { dailyPuzzleHomeViewModel.puzzleDate(for: $0) },
                    progressForOffset: {
                        dailyPuzzleHomeViewModel.progressFraction(
                            for: $0,
                            preferredGridSize: settingsViewModel.model.gridSize
                        )
                    },
                    hoursUntilAvailable: { dailyPuzzleHomeViewModel.hoursUntilAvailable(for: $0) }
                )

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
                    HomeToolbarContent(
                        completedCount: historyViewModel.model.completedCount,
                        streakCount: historyViewModel.model.currentStreak,
                        onCompletedTap: { presentedSheet = .counter(.completedPuzzles) },
                        onStreakTap: { presentedSheet = .counter(.streak) },
                        onSettingsTap: { presentedSheet = .settings },
                        toolbarActionTransitionNamespace: toolbarActionTransitionNamespace
                    )
                }
            }
            .onAppear {
                refreshHomeData(force: true)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                refreshHomeData(force: false)
            }
            .onDisappear {
                presentGameTask?.cancel()
                presentGameTask = nil
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsSheetView(
                        values: settingsViewModel.makeSheetValues()
                    ) { updated in
                        settingsViewModel.save(values: updated)
                        reloadWidgetTimeline()
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
        .environment(\.locale, settingsViewModel.model.appLanguage.locale)
        .font(TypographyTokens.body)
    }

    private func refreshDailyPuzzleState() {
        dailyPuzzleHomeViewModel.refresh(preferredGridSize: settingsViewModel.model.gridSize)
        historyViewModel.refresh()
    }

    private func refreshHomeData(force: Bool) {
        let now = Date()
        if !force,
           now.timeIntervalSince(lastHomeRefreshAt) < Constants.minimumHomeRefreshInterval {
            return
        }

        lastHomeRefreshAt = now
        settingsViewModel.refresh()
        refreshDailyPuzzleState()
        preloadInitialGameData()
    }

    private func preloadInitialGameData() {
        let preferredGridSize = settingsViewModel.model.gridSize
        let launchOffset = dailyPuzzleHomeViewModel.selectedOffset ?? todayOffset
        _ = dailyPuzzleHomeViewModel.puzzleForOffset(
            launchOffset,
            preferredGridSize: preferredGridSize
        )
        _ = dailyPuzzleHomeViewModel.initialProgressRecord(
            for: launchOffset,
            preferredGridSize: preferredGridSize
        )
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
                    reloadWidgetTimeline()
                }
            )
        }
    }

    private func reloadWidgetTimeline() {
        Task { @MainActor in
            WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConfig.widgetKind)
        }
    }

    private func closePresentedGame() {
        presentGameTask?.cancel()
        presentGameTask = nil
        withAnimation(.easeInOut(duration: Constants.closeGameAnimationDuration)) {
            presentedGame = nil
        }
        launchingCardOffset = nil
    }

    private func presentGameFromCard(offset: Int) {
        guard presentedGame == nil else { return }

        presentGameTask?.cancel()

        withAnimation(.easeInOut(duration: Constants.launchCardAnimationDuration)) {
            launchingCardOffset = offset
        }

        presentGameTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Constants.launchCardSettleDelayNanos)
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: Constants.presentGameAnimationDuration)) {
                presentedGame = HostPresentedGame(id: offset)
            }

            try? await Task.sleep(nanoseconds: Constants.launchCardCleanupDelayNanos)
            guard !Task.isCancelled else { return }

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
