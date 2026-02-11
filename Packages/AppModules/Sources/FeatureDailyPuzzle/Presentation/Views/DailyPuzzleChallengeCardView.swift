/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleChallengeCardView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleChallengeCardView,DailyPuzzleChallengeCardGridPreview
 - Funciones clave en este archivo: (sin funciones directas visibles; revisa propiedades/constantes/extensiones)
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

public struct DailyPuzzleChallengeCardView: View {
    private enum PlayButtonSparkle {
        static let repeatIntervalNanos: UInt64 = 5_000_000_000
        static let sweepDuration: Double = 1.0
        static let stripeAngle: Double = 20
        static let stripeOpacity: Double = 0.65
        static let popScale: CGFloat = 1.04
        static let popOffsetY: CGFloat = -1.4
        static let popDuration: Double = 0.58
        static let settleDelayNanos: UInt64 = 470_000_000
        static let settleDuration: Double = 0.64
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var playButtonSparkleProgress: CGFloat = 0
    @State private var playButtonSparkleTask: Task<Void, Never>?
    @State private var playButtonPulseResetTask: Task<Void, Never>?
    @State private var playButtonPulseScale: CGFloat = 1
    @State private var playButtonPulseOffsetY: CGFloat = 0

    public let date: Date
    public let puzzleNumber: Int
    public let grid: [[String]]
    public let words: [String]
    public let foundWords: Set<String>
    public let solvedPositions: Set<GridPosition>
    public let isLocked: Bool
    public let hoursUntilAvailable: Int?
    public let isLaunching: Bool
    public let isFocused: Bool
    public let onPlay: () -> Void

    public init(
        date: Date,
        puzzleNumber: Int,
        grid: [[String]],
        words: [String],
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>,
        isLocked: Bool,
        hoursUntilAvailable: Int?,
        isLaunching: Bool,
        isFocused: Bool,
        onPlay: @escaping () -> Void
    ) {
        self.date = date
        self.puzzleNumber = puzzleNumber
        self.grid = grid
        self.words = words
        self.foundWords = foundWords
        self.solvedPositions = solvedPositions
        self.isLocked = isLocked
        self.hoursUntilAvailable = hoursUntilAvailable
        self.isLaunching = isLaunching
        self.isFocused = isFocused
        self.onPlay = onPlay
    }

    private var totalWords: Int {
        words.count
    }

    private var completedWordsCount: Int {
        min(foundWords.count, totalWords)
    }

    private var isCompleted: Bool {
        totalWords > 0 && completedWordsCount >= totalWords
    }

    private var progressFraction: CGFloat {
        guard totalWords > 0 else { return 0 }
        return CGFloat(completedWordsCount) / CGFloat(totalWords)
    }

    private var shouldDimPreview: Bool {
        isCompleted || isLocked
    }

    private var showsPlayButton: Bool {
        !isLocked && !isCompleted
    }

    private var shouldAnimatePlayButtonSparkle: Bool {
        showsPlayButton && isFocused && !reduceMotion
    }

    private var statusLabel: String {
        if isLocked {
            return lockMessage
        }
        if isCompleted {
            return DailyPuzzleStrings.completed
        }
        return DailyPuzzleStrings.challengeProgress(found: completedWordsCount, total: totalWords)
    }

    public var body: some View {
        ZStack {
            DSCard {
                VStack(spacing: SpacingTokens.sm + 6) {
                    header
                        .carouselParallax(multiplier: 0.04)

                    GeometryReader { geometry in
                        let gridSide = min(geometry.size.width, geometry.size.height)

                        DailyPuzzleChallengeCardGridPreview(
                            grid: grid,
                            words: words,
                            foundWords: foundWords,
                            solvedPositions: solvedPositions,
                            sideLength: gridSide
                        )
                        .frame(width: gridSide, height: gridSide)
                        .saturation(shouldDimPreview ? 0.22 : 1)
                        .opacity(shouldDimPreview ? 0.72 : 1)
                        .blur(radius: shouldDimPreview ? 3 : 0)
                        .carouselParallax(multiplier: 0.08)
                        .overlay(alignment: .center) {
                            statusBadge
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(isLaunching ? 1.08 : 1)
                        .animation(.easeInOut(duration: MotionTokens.normalDuration), value: isLaunching)
                    }
                    .frame(height: 240)

                    footer
                        .carouselParallax(multiplier: 0.04)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous)
                    .dsInnerStroke(ColorTokens.cardHighlightStroke, lineWidth: 1.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous)
                    .dsInnerStroke(ColorTokens.borderDefault, lineWidth: 1)
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous))
        .onTapGesture {
            guard !isCompleted else { return }
            onPlay()
        }
        .onAppear {
            updatePlayButtonSparkleLoop()
        }
        .onDisappear {
            stopPlayButtonSparkleLoop(resetProgress: true)
        }
        .onChange(of: shouldAnimatePlayButtonSparkle) { _, _ in
            updatePlayButtonSparkleLoop()
        }
        .scaleEffect(isLaunching ? 1.02 : 1)
        .animation(.easeInOut(duration: MotionTokens.fastDuration), value: isLocked)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(DailyPuzzleStrings.challengeAccessibilityLabel(number: puzzleNumber, status: statusLabel))
    }

    private var header: some View {
        VStack(spacing: SpacingTokens.xxs - 2) {
            Text(weekdayText)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            Text(monthDayText)
                .font(TypographyTokens.displayTitle)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if isLocked {
            Text(statusLabel)
                .font(TypographyTokens.footnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textSecondary)
        } else {
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(ColorTokens.surfaceSecondary)
                    .frame(width: progressBarWidth, height: progressBarHeight)

                Capsule(style: .continuous)
                    .fill(ColorTokens.accentPrimary)
                    .frame(
                        width: progressBarWidth * progressFraction,
                        height: progressBarHeight
                    )
            }
            .frame(width: progressBarWidth, height: progressBarHeight)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isLocked {
            DSStatusBadge(kind: .locked, size: badgeSize)
        } else if isCompleted {
            DSStatusBadge(kind: .completed, size: badgeSize)
        } else {
            DSButton(
                DailyPuzzleStrings.playChallenge,
                style: .primary,
                cornerRadius: RadiusTokens.infiniteRadius
            ) {
                onPlay()
            }
            .frame(width: playButtonWidth)
            .overlay {
                playButtonSparkleOverlay
            }
            .scaleEffect(playButtonPulseScale)
            .offset(y: playButtonPulseOffsetY)
        }
    }

    private var badgeSize: CGFloat {
        54
    }

    private var playButtonWidth: CGFloat {
        120
    }

    private var progressBarWidth: CGFloat {
        72
    }

    private var progressBarHeight: CGFloat {
        6
    }

    private var playButtonSparkleOverlay: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let stripeWidth = max(24, size.width * 0.28)
            let travelDistance = size.width + (stripeWidth * 2.6)
            let stripeCenterX = (-stripeWidth * 1.3) + (travelDistance * playButtonSparkleProgress)

            LinearGradient(
                colors: [
                    .white.opacity(0),
                    .white.opacity(PlayButtonSparkle.stripeOpacity),
                    .white.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: stripeWidth, height: size.height * 1.8)
            .rotationEffect(.degrees(PlayButtonSparkle.stripeAngle))
            .position(x: stripeCenterX, y: size.height / 2)
            .blendMode(.screen)
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous))
            .opacity(shouldAnimatePlayButtonSparkle ? 1 : 0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func updatePlayButtonSparkleLoop() {
        guard shouldAnimatePlayButtonSparkle else {
            stopPlayButtonSparkleLoop(resetProgress: true)
            return
        }

        guard playButtonSparkleTask == nil else { return }

        playButtonSparkleTask = Task { @MainActor in
            while !Task.isCancelled {
                triggerPlayButtonSparkle()
                try? await Task.sleep(nanoseconds: PlayButtonSparkle.repeatIntervalNanos)
            }
        }
    }

    private func stopPlayButtonSparkleLoop(resetProgress: Bool) {
        playButtonSparkleTask?.cancel()
        playButtonSparkleTask = nil
        playButtonPulseResetTask?.cancel()
        playButtonPulseResetTask = nil

        if resetProgress {
            playButtonSparkleProgress = 0
            playButtonPulseScale = 1
            playButtonPulseOffsetY = 0
        }
    }

    private func triggerPlayButtonSparkle() {
        playButtonPulseResetTask?.cancel()
        playButtonPulseResetTask = nil

        playButtonSparkleProgress = 0
        withAnimation(.easeInOut(duration: PlayButtonSparkle.sweepDuration)) {
            playButtonSparkleProgress = 1
        }

        withAnimation(.easeInOut(duration: PlayButtonSparkle.popDuration)) {
            playButtonPulseScale = PlayButtonSparkle.popScale
            playButtonPulseOffsetY = PlayButtonSparkle.popOffsetY
        }

        playButtonPulseResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: PlayButtonSparkle.settleDelayNanos)
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: PlayButtonSparkle.settleDuration)) {
                playButtonPulseScale = 1
                playButtonPulseOffsetY = 0
            }
        }
    }

    private var lockMessage: String {
        if let hoursUntilAvailable {
            return DailyPuzzleStrings.challengeAvailableIn(hours: hoursUntilAvailable)
        }
        return DailyPuzzleStrings.challengeAvailableSoon
    }

    private var monthDayText: String {
        let locale = AppLocalization.currentLocale
        return date
            .formatted(
                .dateTime
                    .locale(locale)
                    .day()
                    .month(.abbreviated)
            )
            .uppercased(with: locale)
    }

    private var weekdayText: String {
        let locale = AppLocalization.currentLocale
        return date
            .formatted(
                .dateTime
                    .locale(locale)
                    .weekday(.wide)
            )
            .capitalized(with: locale)
    }
}

private struct DailyPuzzleChallengeCardGridPreview: View {
    let grid: [[String]]
    let words: [String]
    let foundWords: Set<String>
    let solvedPositions: Set<GridPosition>
    let sideLength: CGFloat

    private var outlines: [SharedWordSearchBoardOutline] {
        let normalizedFoundWords = Set(foundWords.map(WordSearchNormalization.normalizedWord))
        let coreGrid = Core.PuzzleGrid(letters: grid)

        return words.enumerated().compactMap { index, word in
            let normalized = WordSearchNormalization.normalizedWord(word)
            guard normalizedFoundWords.contains(normalized) else { return nil }
            guard let path = WordPathFinderService.bestPath(
                for: normalized,
                grid: coreGrid,
                prioritizing: solvedPositions
            ) else {
                return nil
            }
            let boardPath = path.map { SharedWordSearchBoardPosition(row: $0.row, col: $0.col) }
            return SharedWordSearchBoardOutline(
                id: "preview-\(index)-\(normalized)",
                word: normalized,
                seed: index,
                positions: boardPath
            )
        }
    }

    var body: some View {
        SharedWordSearchBoardView(
            grid: grid,
            sideLength: sideLength,
            activePositions: [],
            feedback: nil,
            solvedWordOutlines: outlines,
            anchor: nil,
            palette: WordSearchBoardStylePreset.challengePreview
        )
        .scaleEffect(0.96)
    }
}

#Preview("Challenge Card States") {
    PreviewThemeProvider {
        VStack(spacing: SpacingTokens.md) {
            DailyPuzzleChallengeCardView(
                date: .now,
                puzzleNumber: 1,
                grid: Array(repeating: Array(repeating: "A", count: 8), count: 8),
                words: ["ARBOL", "RIO", "LUNA", "NUBE"],
                foundWords: ["ARBOL"],
                solvedPositions: [],
                isLocked: false,
                hoursUntilAvailable: nil,
                isLaunching: false,
                isFocused: true
            ) {}
            .frame(width: 320, height: 360)

            DailyPuzzleChallengeCardView(
                date: .now.addingTimeInterval(86_400),
                puzzleNumber: 2,
                grid: Array(repeating: Array(repeating: "B", count: 8), count: 8),
                words: ["ARBOL", "RIO", "LUNA", "NUBE"],
                foundWords: [],
                solvedPositions: [],
                isLocked: true,
                hoursUntilAvailable: 5,
                isLaunching: false,
                isFocused: false
            ) {}
            .frame(width: 320, height: 360)
        }
    }
}
