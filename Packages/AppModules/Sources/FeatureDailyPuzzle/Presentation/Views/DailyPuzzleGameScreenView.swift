/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleGameScreenView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleSharedSyncContext,DailyPuzzleCelebrationPreferences DailyPuzzleSelectionFeedbackKind,DailyPuzzleSelectionFeedback
 - Funciones clave en este archivo: celebrateWord,handleDragChanged handleDragEnded,finalizeSelection saveProgress,resetProgress
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

import SwiftUI
import Core
import DesignSystem

public struct DailyPuzzleSharedSyncContext: Sendable {
    public let puzzleIndex: Int

    public init(puzzleIndex: Int) {
        self.puzzleIndex = puzzleIndex
    }
}

public struct DailyPuzzleCelebrationPreferences: Equatable, Sendable {
    public let enableCelebrations: Bool
    public let enableHaptics: Bool
    public let enableSound: Bool
    public let intensity: CelebrationIntensity

    public init(
        enableCelebrations: Bool,
        enableHaptics: Bool,
        enableSound: Bool,
        intensity: CelebrationIntensity
    ) {
        self.enableCelebrations = enableCelebrations
        self.enableHaptics = enableHaptics
        self.enableSound = enableSound
        self.intensity = intensity
    }
}

private enum DailyPuzzleSelectionFeedbackKind {
    case correct
    case incorrect
}

private struct DailyPuzzleSelectionFeedback: Identifiable {
    let id = UUID()
    let kind: DailyPuzzleSelectionFeedbackKind
    let positions: [GridPosition]
}

private struct DailyPuzzleEntryState {
    var boardVisible = false
    var bottomVisible = false
    var didRun = false
}

private struct DailyPuzzleCompletionOverlayState {
    var isVisible = false
    var showsBackdrop = false
    var showsToast = false
    var streakLabel: String?

    static let hidden = DailyPuzzleCompletionOverlayState()
}

private struct DailyPuzzleWordToastState: Identifiable {
    let id = UUID()
    let message: String
}

private struct DailyPuzzleCelebrationConfig {
    let brushDuration: TimeInterval
    let waveDuration: TimeInterval
    let sparkleTailDuration: TimeInterval

    static let `default` = DailyPuzzleCelebrationConfig(
        brushDuration: 0.18,
        waveDuration: 0.42,
        sparkleTailDuration: 0.16
    )
}

@MainActor
private final class DailyPuzzleCelebrationController: ObservableObject {
    @Published private(set) var boardCelebrations: [DailyPuzzleBoardCelebration] = []

    private let config = DailyPuzzleCelebrationConfig.default

    func celebrateWord(
        pathCells: [GridPosition],
        preferences: DailyPuzzleCelebrationPreferences,
        reduceMotion: Bool,
        onFeedback: (DailyPuzzleCelebrationPreferences) -> Void
    ) {
        onFeedback(preferences)

        guard preferences.enableCelebrations else { return }
        guard !pathCells.isEmpty else { return }

        let celebration = DailyPuzzleBoardCelebration(
            positions: pathCells,
            intensity: preferences.intensity,
            popDuration: config.brushDuration,
            particleDuration: config.waveDuration,
            reduceMotion: reduceMotion
        )

        boardCelebrations.append(celebration)

        let adjustedWaveDuration = max(
            config.waveDuration * preferences.intensity.sequenceWaveFactor,
            Double(pathCells.count) * 0.045
        )
        let removalDelay = config.brushDuration + adjustedWaveDuration + config.sparkleTailDuration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(removalDelay * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.18)) {
                    boardCelebrations.removeAll { $0.id == celebration.id }
                }
            }
        }
    }
}

private struct DailyPuzzleWordToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(TypographyTokens.bodyStrong)
            .foregroundStyle(ColorTokens.inkPrimary)
            .padding(.horizontal, SpacingTokens.md)
            .padding(.vertical, SpacingTokens.xs)
            .background {
                Capsule()
                    .fill(ThemeGradients.brushWarm)
                    .overlay {
                        Capsule()
                            .stroke(ColorTokens.accentAmberStrong.opacity(0.28), lineWidth: 1)
                    }
            }
            .shadow(color: ColorTokens.accentAmberStrong.opacity(0.18), radius: 8, x: 0, y: 4)
            .accessibilityAddTraits(.isStaticText)
    }
}

private extension CelebrationIntensity {
    var sequenceWaveFactor: Double {
        switch self {
        case .low:
            return 1.08
        case .medium:
            return 1
        case .high:
            return 0.9
        }
    }

    var fxValue: Float {
        switch self {
        case .low:
            return 0.55
        case .medium:
            return 0.78
        case .high:
            return 1
        }
    }
}

public struct DailyPuzzleGameScreenView: View {
    private enum Constants {
        static let entryBoardDuration: Double = 0.22
        static let entryBottomSpringResponse: Double = 0.34
        static let entryBottomSpringDamping: Double = 0.88
        static let entryBottomDelayNanos: UInt64 = 90_000_000

        static let feedbackShowDuration: Double = 0.08
        static let feedbackHideDelayNanos: UInt64 = 650_000_000

        static let completionBackdropDuration: Double = 0.12
        static let completionToastDelayNanos: UInt64 = 120_000_000
        static let completionAutoDismissDelayNanos: UInt64 = 1_500_000_000
        static let completionHideToastDuration: Double = 0.14
        static let completionHideToastDelayNanos: UInt64 = 100_000_000
        static let completionHideBackdropDuration: Double = 0.1
        static let completionHideBackdropDelayNanos: UInt64 = 110_000_000

        static let wordToastShowDuration: Double = 0.2
        static let wordToastHideDuration: Double = 0.22
        static let wordToastVisibleNanos: UInt64 = 980_000_000
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public let core: CoreContainer
    public let dayOffset: Int
    public let todayOffset: Int
    public let navigationTitle: String
    public let puzzle: Puzzle
    public let gridSize: Int
    public let wordHintMode: WordHintMode
    public let initialProgress: AppProgressRecord?
    public let sharedSync: DailyPuzzleSharedSyncContext?
    public let onProgressUpdate: () -> Void
    public let onClose: (() -> Void)?
    public let celebrationPreferencesProvider: () -> DailyPuzzleCelebrationPreferences
    public let onWordFeedback: (DailyPuzzleCelebrationPreferences) -> Void
    public let onCompletionFeedback: (DailyPuzzleCelebrationPreferences) -> Void
    public let onSharedStateMutation: () -> Void

    @StateObject private var celebrationController = DailyPuzzleCelebrationController()
    @StateObject private var fxManager = MetalFXManager()
    @State private var gameSession: DailyPuzzleGameSessionViewModel
    @State private var activeSelection: [GridPosition] = []
    @State private var dragAnchor: GridPosition?
    @State private var selectionFeedback: DailyPuzzleSelectionFeedback?
    @State private var gridBounds: CGRect = .zero
    @State private var feedbackNonce = 0
    @State private var showResetAlert = false
    @State private var entryState = DailyPuzzleEntryState()
    @State private var completionOverlay = DailyPuzzleCompletionOverlayState.hidden
    @State private var wordToast: DailyPuzzleWordToastState?
    @State private var wordToastIndex = 0
    @State private var wordToastNonce = 0
    @State private var entryTransitionTask: Task<Void, Never>?
    @State private var feedbackDismissTask: Task<Void, Never>?
    @State private var completionOverlayTask: Task<Void, Never>?
    @State private var wordToastDismissTask: Task<Void, Never>?

    public init(
        core: CoreContainer,
        dayOffset: Int,
        todayOffset: Int,
        navigationTitle: String,
        puzzle: Puzzle,
        gridSize: Int,
        wordHintMode: WordHintMode,
        initialProgress: AppProgressRecord?,
        sharedSync: DailyPuzzleSharedSyncContext?,
        onProgressUpdate: @escaping () -> Void,
        onClose: (() -> Void)? = nil,
        celebrationPreferencesProvider: @escaping () -> DailyPuzzleCelebrationPreferences,
        onWordFeedback: @escaping (DailyPuzzleCelebrationPreferences) -> Void = { _ in },
        onCompletionFeedback: @escaping (DailyPuzzleCelebrationPreferences) -> Void = { _ in },
        onSharedStateMutation: @escaping () -> Void = {}
    ) {
        self.core = core
        self.dayOffset = dayOffset
        self.todayOffset = todayOffset
        self.navigationTitle = navigationTitle
        self.puzzle = puzzle
        self.gridSize = gridSize
        self.wordHintMode = wordHintMode
        self.initialProgress = initialProgress
        self.sharedSync = sharedSync
        self.onProgressUpdate = onProgressUpdate
        self.onClose = onClose
        self.celebrationPreferencesProvider = celebrationPreferencesProvider
        self.onWordFeedback = onWordFeedback
        self.onCompletionFeedback = onCompletionFeedback
        self.onSharedStateMutation = onSharedStateMutation

        let initialFoundWords = Set(initialProgress?.foundWords ?? [])
        let initialSolvedPositions = Set(initialProgress?.solvedPositions ?? [])

        _gameSession = State(
            initialValue: DailyPuzzleGameSessionViewModel(
                dayKey: DayKey(offset: dayOffset),
                gridSize: gridSize,
                puzzle: puzzle,
                foundWords: initialFoundWords,
                solvedPositions: initialSolvedPositions,
                startedAt: initialProgress?.startedDate,
                endedAt: initialProgress?.endedDate
            )
        )
    }

    private var isCompleted: Bool {
        gameSession.isCompleted
    }

    public var body: some View {
        ZStack {
            DSPageBackgroundView(gridOpacity: 0.09)

            GeometryReader { geometry in
                let side = min(geometry.size.width - SpacingTokens.xl, 420)

                VStack(spacing: SpacingTokens.lg) {
                    ZStack(alignment: .topLeading) {
                        DailyPuzzleGameBoardView(
                            grid: puzzle.grid.letters,
                            words: puzzle.words.map(\.text),
                            foundWords: gameSession.foundWords,
                            solvedPositions: gameSession.solvedPositions,
                            activePositions: activeSelection,
                            feedback: selectionFeedback.map {
                                DailyPuzzleBoardFeedback(
                                    id: $0.id,
                                    kind: $0.kind == .correct ? .correct : .incorrect,
                                    positions: $0.positions
                                )
                            },
                            celebrations: celebrationController.boardCelebrations,
                            sideLength: side
                        ) { position in
                            guard !isCompleted else { return }
                            handleDragChanged(position)
                        } onDragEnded: {
                            guard !isCompleted else { return }
                            handleDragEnded()
                        }
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: DailyPuzzleGridFramePreferenceKey.self,
                                    value: CGRect(origin: .zero, size: proxy.size)
                                )
                            }
                        }

                        if gridBounds.width > 0, gridBounds.height > 0 {
                            MetalFXView(manager: fxManager, size: gridBounds.size)
                                .frame(width: gridBounds.width, height: gridBounds.height)
                                .allowsHitTesting(false)
                        }
                    }
                    .onPreferenceChange(DailyPuzzleGridFramePreferenceKey.self) { bounds in
                        guard bounds.width > 0, bounds.height > 0 else { return }
                        gridBounds = bounds
                    }
                    .opacity(entryState.boardVisible ? 1 : 0)
                    .scaleEffect(entryState.boardVisible ? 1 : 0.98)

                    objectivesView
                        .offset(y: entryState.bottomVisible ? 0 : 24)
                        .opacity(entryState.bottomVisible ? 1 : 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .clipped()
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.top, SpacingTokens.sm)
                .padding(.bottom, 0)
            }
            .allowsHitTesting(!completionOverlay.isVisible)

            if let wordToast, !completionOverlay.isVisible {
                VStack {
                    DailyPuzzleWordToastView(message: wordToast.message)
                    Spacer()
                }
                .padding(.top, SpacingTokens.md)
                .padding(.horizontal, SpacingTokens.lg)
                .allowsHitTesting(false)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(2)
            }

            if completionOverlay.isVisible {
                DailyPuzzleCompletionOverlayView(
                    showBackdrop: completionOverlay.showsBackdrop,
                    showToast: completionOverlay.showsToast,
                    streakLabel: completionOverlay.streakLabel,
                    reduceMotion: reduceMotion,
                    reduceTransparency: reduceTransparency,
                    onTapDismiss: {
                        Task { @MainActor in
                            await dismissCompletionOverlay()
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.down")
                    }
                    .accessibilityLabel(DailyPuzzleStrings.close)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showResetAlert = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel(DailyPuzzleStrings.resetChallenge)
            }
        }
        .onAppear {
            let preferences = celebrationPreferencesProvider()
            fxManager.setSuccessFXEnabled(preferences.enableCelebrations)
            if gameSession.startIfNeeded() {
                saveProgress()
            }
            runEntryTransition()
        }
        .onDisappear {
            entryTransitionTask?.cancel()
            entryTransitionTask = nil
            feedbackDismissTask?.cancel()
            feedbackDismissTask = nil
            wordToastDismissTask?.cancel()
            wordToastDismissTask = nil
            completionOverlayTask?.cancel()
            completionOverlayTask = nil
        }
        .alert(DailyPuzzleStrings.resetAlertTitle, isPresented: $showResetAlert) {
            Button(DailyPuzzleStrings.resetAlertCancel, role: .cancel) {}
            Button(DailyPuzzleStrings.resetAlertConfirm, role: .destructive) {
                resetProgress()
            }
        } message: {
            Text(DailyPuzzleStrings.resetAlertMessage)
        }
    }

}

private extension DailyPuzzleGameScreenView {
    var objectivesView: some View {
        DailyPuzzleWordsView(
            words: puzzle.words.map(\.text),
            foundWords: gameSession.foundWords,
            displayMode: wordHintMode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func handleDragChanged(_ position: GridPosition) {
        if dragAnchor == nil {
            dragAnchor = position
            activeSelection = [position]
            if gameSession.startIfNeeded() {
                saveProgress()
            }
            return
        }

        guard let anchor = dragAnchor else { return }
        let direction = SelectionValidationService.snappedDirection(from: anchor, to: position)
        activeSelection = SelectionValidationService.selectionPath(
            from: anchor,
            to: position,
            direction: direction,
            grid: puzzle.grid
        )
    }

    private func handleDragEnded() {
        let selection = activeSelection
        dragAnchor = nil
        guard selection.count >= 2 else {
            activeSelection = []
            return
        }
        finalizeSelection(selection)
        activeSelection = []
    }

    private func finalizeSelection(_ positions: [GridPosition]) {
        let outcome = gameSession.finalizeSelection(positions)
        switch outcome.kind {
        case .ignored:
            return
        case .incorrect:
            showFeedback(kind: .incorrect, positions: positions)
            return
        case .correct:
            showFeedback(kind: .correct, positions: positions)
            showWordToast()
        }

        let completedNow = outcome.completedPuzzleNow
        onWordValidated(pathCells: positions, isPuzzleComplete: completedNow)

        var completionStreak: Int?
        if completedNow {
            core.markCompletedDayUseCase.execute(dayKey: DayKey(offset: dayOffset))
            if dayOffset == todayOffset {
                let streakState = core.updateStreakUseCase.markCompleted(
                    dayKey: DayKey(offset: dayOffset),
                    todayKey: DayKey(offset: todayOffset)
                )
                completionStreak = streakState.current
                _ = core.rewardCompletionHintUseCase.execute(
                    dayKey: DayKey(offset: dayOffset),
                    todayKey: DayKey(offset: todayOffset)
                )
            }
        }
        saveProgress()
        if completedNow {
            let preferences = celebrationPreferencesProvider()
            presentCompletionOverlay(streakCount: completionStreak, preferences: preferences)
        }
    }

    private func saveProgress() {
        let record = AppProgressRecord(
            dayOffset: dayOffset,
            gridSize: gridSize,
            foundWords: Array(gameSession.foundWords),
            solvedPositions: Array(gameSession.solvedPositions),
            startedAt: gameSession.startedAt?.timeIntervalSince1970,
            endedAt: gameSession.endedAt?.timeIntervalSince1970
        )
        if let sharedSync {
            core.updateSharedProgressUseCase.execute(
                puzzleIndex: sharedSync.puzzleIndex,
                gridSize: gridSize,
                foundWords: gameSession.foundWords,
                solvedPositions: gameSession.solvedPositions
            )
            onSharedStateMutation()
        } else {
            core.saveProgressRecordUseCase.execute(record)
        }
        onProgressUpdate()
    }

    private func resetProgress() {
        entryTransitionTask?.cancel()
        entryTransitionTask = nil
        feedbackDismissTask?.cancel()
        feedbackDismissTask = nil
        wordToastDismissTask?.cancel()
        wordToastDismissTask = nil
        wordToast = nil
        completionOverlayTask?.cancel()
        completionOverlayTask = nil
        completionOverlay = .hidden
        gameSession.reset()
        activeSelection = []
        dragAnchor = nil
        if let sharedSync {
            core.clearSharedProgressUseCase.execute(
                puzzleIndex: sharedSync.puzzleIndex,
                preferredGridSize: core.loadSettingsUseCase.execute().gridSize
            )
            onSharedStateMutation()
        } else {
            core.resetProgressRecordUseCase.execute(
                dayKey: DayKey(offset: dayOffset),
                gridSize: gridSize
            )
        }
        onProgressUpdate()
    }

    private func runEntryTransition() {
        guard !entryState.didRun else { return }
        entryState.didRun = true

        if reduceMotion {
            entryState.boardVisible = true
            entryState.bottomVisible = true
            return
        }

        entryTransitionTask?.cancel()
        entryTransitionTask = Task { @MainActor in
            withAnimation(.easeInOut(duration: Constants.entryBoardDuration)) {
                entryState.boardVisible = true
            }
            try? await Task.sleep(nanoseconds: Constants.entryBottomDelayNanos)
            guard !Task.isCancelled else { return }
            withAnimation(
                .spring(
                    response: Constants.entryBottomSpringResponse,
                    dampingFraction: Constants.entryBottomSpringDamping
                )
            ) {
                entryState.bottomVisible = true
            }
        }
    }

    private func showFeedback(kind: DailyPuzzleSelectionFeedbackKind, positions: [GridPosition]) {
        feedbackNonce += 1
        let currentNonce = feedbackNonce
        withAnimation(.easeOut(duration: Constants.feedbackShowDuration)) {
            selectionFeedback = DailyPuzzleSelectionFeedback(kind: kind, positions: positions)
        }

        feedbackDismissTask?.cancel()
        feedbackDismissTask = Task {
            try? await Task.sleep(nanoseconds: Constants.feedbackHideDelayNanos)
            guard !Task.isCancelled else { return }
            guard currentNonce == feedbackNonce else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: Constants.feedbackShowDuration)) {
                    selectionFeedback = nil
                }
            }
        }
    }

    private func showWordToast() {
        wordToastNonce += 1
        let nonce = wordToastNonce
        let message = DailyPuzzleStrings.wordFeedbackMessage(at: wordToastIndex)
        wordToastIndex += 1

        withAnimation(
            reduceMotion
                ? .easeInOut(duration: Constants.wordToastShowDuration)
                : .spring(response: 0.34, dampingFraction: 0.86)
        ) {
            wordToast = DailyPuzzleWordToastState(message: message)
        }

        wordToastDismissTask?.cancel()
        wordToastDismissTask = Task {
            try? await Task.sleep(
                nanoseconds: reduceMotion ? 760_000_000 : Constants.wordToastVisibleNanos
            )
            guard !Task.isCancelled else { return }
            guard nonce == wordToastNonce else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: Constants.wordToastHideDuration)) {
                    wordToast = nil
                }
            }
        }
    }

    private func onWordValidated(pathCells: [GridPosition], isPuzzleComplete: Bool) {
        let preferences = celebrationPreferencesProvider()
        onWordFeedback(preferences)
        fxManager.setSuccessFXEnabled(preferences.enableCelebrations)
        guard let context = makeWordPathFXContext(pathCells: pathCells) else { return }
        let waveIntensity = max(0.32 as Float, preferences.intensity.fxValue * 0.78)
        let particlesIntensity = max(0.28 as Float, preferences.intensity.fxValue * 0.68)
        triggerWordSuccessWave(context: context, intensity: waveIntensity)
        triggerWordSuccessParticles(context: context, intensity: particlesIntensity)
        if isPuzzleComplete {
            let confettiIntensity = min(1 as Float, preferences.intensity.fxValue * 0.84 + 0.08)
            triggerCompletionConfetti(in: context.bounds, intensity: confettiIntensity)
        }
    }

    private func triggerWordSuccessWave(
        context: (bounds: CGRect, centers: [CGPoint]),
        intensity: Float
    ) {
        fxManager.play(
            FXEvent(
                type: .wordSuccessWave,
                timestamp: ProcessInfo.processInfo.systemUptime,
                gridBounds: context.bounds,
                pathPoints: context.centers,
                cellCenters: context.centers,
                wordRects: nil,
                intensity: intensity
            )
        )
    }

    private func triggerWordSuccessParticles(
        context: (bounds: CGRect, centers: [CGPoint]),
        intensity: Float
    ) {
        fxManager.play(
            FXEvent(
                type: .wordSuccessParticles,
                timestamp: ProcessInfo.processInfo.systemUptime,
                gridBounds: context.bounds,
                pathPoints: context.centers,
                cellCenters: context.centers,
                wordRects: nil,
                intensity: intensity
            )
        )
    }

    private func triggerCompletionConfetti(in bounds: CGRect, intensity: Float) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let top = CGPoint(x: bounds.midX, y: bounds.minY + bounds.height * 0.12)
        let bottom = CGPoint(x: bounds.midX, y: bounds.maxY - bounds.height * 0.08)

        fxManager.play(
            FXEvent(
                type: .wordCompletionConfetti,
                timestamp: ProcessInfo.processInfo.systemUptime,
                gridBounds: bounds,
                pathPoints: [top, center, bottom],
                cellCenters: [center],
                wordRects: nil,
                intensity: intensity
            )
        )
    }

    private func makeWordPathFXContext(pathCells: [GridPosition]) -> (bounds: CGRect, centers: [CGPoint])? {
        guard gridBounds.width > 0, gridBounds.height > 0 else { return nil }

        let localGridBounds = CGRect(origin: .zero, size: gridBounds.size)
        let rows = max(puzzle.grid.rowCount, 1)
        let cols = max(puzzle.grid.columnCount, 1)
        let centers = MetalFXGridGeometry.pathPoints(
            for: pathCells,
            in: localGridBounds,
            rows: rows,
            cols: cols
        )
        guard !centers.isEmpty else { return nil }
        return (localGridBounds, centers)
    }

    private func presentCompletionOverlay(
        streakCount: Int?,
        preferences: DailyPuzzleCelebrationPreferences
    ) {
        wordToastDismissTask?.cancel()
        wordToastDismissTask = nil
        wordToast = nil

        completionOverlayTask?.cancel()
        completionOverlay = DailyPuzzleCompletionOverlayState(
            isVisible: true,
            showsBackdrop: false,
            showsToast: false,
            streakLabel: streakCount.map(DailyPuzzleStrings.streakLabel(_:))
        )

        onCompletionFeedback(preferences)

        withAnimation(.easeInOut(duration: Constants.completionBackdropDuration)) {
            completionOverlay.showsBackdrop = true
        }

        completionOverlayTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Constants.completionToastDelayNanos)
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.16) : .easeOut(duration: 0.2)) {
                completionOverlay.showsToast = true
            }

            try? await Task.sleep(nanoseconds: Constants.completionAutoDismissDelayNanos)
            guard !Task.isCancelled else { return }
            await dismissCompletionOverlay(cancelScheduledTask: false)
        }
    }

    @MainActor
    private func dismissCompletionOverlay(cancelScheduledTask: Bool = true) async {
        if cancelScheduledTask {
            completionOverlayTask?.cancel()
            completionOverlayTask = nil
        }

        withAnimation(.easeInOut(duration: Constants.completionHideToastDuration)) {
            completionOverlay.showsToast = false
        }

        try? await Task.sleep(nanoseconds: Constants.completionHideToastDelayNanos)

        withAnimation(.easeInOut(duration: Constants.completionHideBackdropDuration)) {
            completionOverlay.showsBackdrop = false
        }

        try? await Task.sleep(nanoseconds: Constants.completionHideBackdropDelayNanos)

        completionOverlay.isVisible = false
        completionOverlay.streakLabel = nil
        if !cancelScheduledTask {
            completionOverlayTask = nil
        }
    }
}
