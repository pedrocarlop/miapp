//
//  ContentView.swift
//  miapp
//
//  Created by Pedro Carrasco lopez brea on 8/2/26.
//

import SwiftUI
import Combine
import WidgetKit
import UIKit
import AudioToolbox

private struct HostPresentedGame: Identifiable, Equatable {
    let id: Int
}

private enum HostGlassRole {
    case chip
    case control
    case panel
    case loupe
    case banner
}

private enum HostDesignTokens {
    static let cardCornerRadius: CGFloat = 28
    static let panelCornerRadius: CGFloat = 20
    static let chipCornerRadius: CGFloat = 14

    static func material(for role: HostGlassRole) -> Material {
        switch role {
        case .chip:
            return .thinMaterial
        case .control:
            return .regularMaterial
        case .panel:
            return .thickMaterial
        case .loupe:
            return .thinMaterial
        case .banner:
            return .thickMaterial
        }
    }

    static func fallbackColor(for role: HostGlassRole) -> Color {
        switch role {
        case .chip:
            return Color(.secondarySystemBackground)
        case .control:
            return Color(.secondarySystemBackground)
        case .panel:
            return Color(.systemBackground)
        case .loupe:
            return Color(.tertiarySystemBackground)
        case .banner:
            return Color(.secondarySystemBackground)
        }
    }

    static func fillStyle(for role: HostGlassRole, reduceTransparency: Bool) -> AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(fallbackColor(for: role))
        }
        return AnyShapeStyle(material(for: role))
    }

    static func strokeColor(for contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? Color.primary.opacity(0.45) : Color.secondary.opacity(0.22)
    }
}

private struct SoftGlowBackground: View {
    var body: some View {
        Color(.systemGroupedBackground)
        .ignoresSafeArea()
    }
}

private struct GlassPanel<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let role: HostGlassRole
    let cornerRadius: CGFloat
    let contentPadding: EdgeInsets
    let content: Content

    init(
        role: HostGlassRole = .panel,
        cornerRadius: CGFloat = HostDesignTokens.panelCornerRadius,
        contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        @ViewBuilder content: () -> Content
    ) {
        self.role = role
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(HostDesignTokens.fillStyle(for: role, reduceTransparency: reduceTransparency))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        HostDesignTokens.strokeColor(for: colorSchemeContrast),
                        lineWidth: 1
                    )
            )
    }
}

private struct GlassChip<Content: View>: View {
    let role: HostGlassRole
    let action: (() -> Void)?
    let content: Content

    init(
        role: HostGlassRole = .chip,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.role = role
        self.action = action
        self.content = content()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    chipBody
                }
                .buttonStyle(.plain)
            } else {
                chipBody
            }
        }
    }

    private var chipBody: some View {
        GlassPanel(
            role: role,
            cornerRadius: HostDesignTokens.chipCornerRadius,
            contentPadding: EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        ) {
            content
                .font(.subheadline.weight(.semibold))
        }
    }
}

private struct GlassBanner: View {
    let systemImage: String
    let title: String
    let message: String?

    var body: some View {
        GlassPanel(
            role: .banner,
            cornerRadius: 18,
            contentPadding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        ) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    if let message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HomeNavCounter: View {
    let value: Int
    let systemImage: String
    let tint: Color
    let accessibilityLabel: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text("\(value)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct DailyChallengeCard: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let date: Date
    let puzzle: HostPuzzle
    let progress: HostPuzzleProgress
    let isLocked: Bool
    let hoursUntilAvailable: Int?
    let isLaunching: Bool
    let onPlay: () -> Void

    private var totalWords: Int { puzzle.words.count }
    private var isCompleted: Bool {
        totalWords > 0 && progress.foundWords.count >= totalWords
    }

    var body: some View {
        ZStack {
            GlassPanel(
                role: .panel,
                cornerRadius: HostDesignTokens.cardCornerRadius,
                contentPadding: EdgeInsets(top: 40, leading: 20, bottom: 40, trailing: 20)
            ) {
                VStack(spacing: 14) {
                    VStack(spacing: -4) {
                        Text(HostDateFormatter.weekdayName(for: date).capitalized)
                            .font(.system(size: 54, weight: .semibold, design: .default))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)

                        Text(HostDateFormatter.monthDayCompact(for: date))
                            .font(.system(size: 68, weight: .semibold, design: .default))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                    }

                    GeometryReader { geometry in
                        let gridSide = min(geometry.size.width, geometry.size.height)
                        PuzzleGridPreview(
                            grid: puzzle.grid,
                            words: puzzle.words,
                            foundWords: progress.foundWords,
                            solvedPositions: progress.solvedPositions,
                            sideLength: gridSide
                        )
                        .frame(width: gridSide, height: gridSide)
                        .blur(radius: isCompleted ? 4 : 0)
                        .overlay {
                            if isCompleted {
                                let previewShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

                                ZStack {
                                    previewShape
                                        .fill(
                                            reduceTransparency
                                            ? AnyShapeStyle(Color.white.opacity(0.88))
                                            : AnyShapeStyle(.ultraThinMaterial)
                                        )

                                    previewShape
                                        .fill(Color.white.opacity(0.24))

                                    VStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text("Completado")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .clipShape(previewShape)
                                .overlay(
                                    previewShape
                                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(isLaunching ? 1.08 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isLaunching)
                    }
                    .frame(height: 240)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: HostDesignTokens.cardCornerRadius, style: .continuous)
                    .stroke(Color(.systemBackground), lineWidth: 1.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HostDesignTokens.cardCornerRadius, style: .continuous)
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
            .opacity(1)

            if isLocked {
                ZStack {
                    RoundedRectangle(cornerRadius: HostDesignTokens.cardCornerRadius, style: .continuous)
                        .fill(
                            reduceTransparency
                            ? AnyShapeStyle(Color(.systemBackground).opacity(0.84))
                            : AnyShapeStyle(.regularMaterial)
                        )

                    RoundedRectangle(cornerRadius: HostDesignTokens.cardCornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.04))

                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                        Text("Reto bloqueado")
                            .font(.headline)
                        Text(lockMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .combine)
                }
                .clipShape(RoundedRectangle(cornerRadius: HostDesignTokens.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: HostDesignTokens.cardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
                .allowsHitTesting(false)
            }

        }
        .contentShape(RoundedRectangle(cornerRadius: HostDesignTokens.cardCornerRadius, style: .continuous))
        .onTapGesture {
            guard !isCompleted else { return }
            onPlay()
        }
        .scaleEffect(isLaunching ? 1.02 : 1)
        .animation(.easeInOut(duration: 0.2), value: isLocked)
    }

    private var lockMessage: String {
        if let hoursUntilAvailable {
            return "Disponible en \(hoursUntilAvailable)h"
        }
        return "Disponible pronto"
    }

}

private struct DayCarouselView: View {
    let offsets: [Int]
    @Binding var selectedOffset: Int?
    let todayOffset: Int
    let unlockedOffsets: Set<Int>
    let completedOffsets: Set<Int>
    let dateForOffset: (Int) -> Date
    let hoursUntilAvailable: (Int) -> Int?

    var body: some View {
        GeometryReader { geo in
            let itemWidth: CGFloat = 78
            let sidePadding = max((geo.size.width - itemWidth) / 2, 16)
            let activeOffset = selectedOffset ?? todayOffset
            let scrollSelection = Binding<Int?>(
                get: {
                    let current = selectedOffset ?? todayOffset
                    return offsets.contains(current) ? current : nil
                },
                set: { selectedOffset = $0 }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(offsets, id: \.self) { offset in
                        let date = dateForOffset(offset)
                        let isLocked = offset > todayOffset && !unlockedOffsets.contains(offset)
                        DayCarouselItem(
                            date: date,
                            isSelected: offset == activeOffset,
                            isLocked: isLocked,
                            isCompleted: completedOffsets.contains(offset),
                            hoursUntilAvailable: hoursUntilAvailable(offset)
                        )
                        .frame(width: itemWidth)
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.28, extraBounce: 0.02)) {
                                selectedOffset = offset
                            }
                        }
                        .id(offset)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, sidePadding)
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: scrollSelection, anchor: .center)
        }
    }
}

private struct DayCarouselItem: View {
    let date: Date
    let isSelected: Bool
    let isLocked: Bool
    let isCompleted: Bool
    let hoursUntilAvailable: Int?

    var body: some View {
        GlassPanel(
            role: .chip,
            cornerRadius: 20,
            contentPadding: EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)
        ) {
            VStack(spacing: 6) {
                Text(HostDateFormatter.shortWeekday(for: date).uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.title3.weight(.bold))

                statusView
                    .frame(height: 14, alignment: .center)
            }
        }
        .scaleEffect(isSelected ? 1.04 : 0.98)
        .opacity(isSelected ? 1 : 0.92)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    @ViewBuilder
    private var statusView: some View {
        if isLocked, let hoursUntilAvailable {
            Text("\(hoursUntilAvailable)h")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else if isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.black)
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 6, height: 6)
        }
    }
}

private struct ProgressBarView: View {
    let progress: Double
    let label: String

    var body: some View {
        let clamped = max(0, min(progress, 1))

        GlassPanel(
            role: .panel,
            cornerRadius: HostDesignTokens.panelCornerRadius,
            contentPadding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ProgressView(value: clamped)
                    .tint(Color.accentColor)
                    .accessibilityLabel("Progreso de palabras")
                    .accessibilityValue("\(Int(clamped * 100)) por ciento")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: clamped)
    }
}

private enum HostSelectionFeedbackKind {
    case correct
    case incorrect
}

private struct HostSelectionFeedback: Identifiable {
    let id = UUID()
    let kind: HostSelectionFeedbackKind
    let positions: [HostGridPosition]
}

private struct HostSharedSyncContext {
    let puzzleIndex: Int
}

struct LoupeConfiguration {
    var size: CGSize
    var magnification: CGFloat
    var offset: CGSize
    var edgePadding: CGFloat
    var cornerRadius: CGFloat
    var borderWidth: CGFloat
    var glassOpacity: Double
    var highlightOpacity: Double
    var glowOpacity: Double
    var blurRadius: CGFloat
    var smoothing: CGFloat
    var material: Material

    init(
        size: CGSize = CGSize(width: 110, height: 110),
        magnification: CGFloat = 1.7,
        offset: CGSize = CGSize(width: 0, height: -70),
        edgePadding: CGFloat = 8,
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat = 1.2,
        glassOpacity: Double = 0.9,
        highlightOpacity: Double = 0.35,
        glowOpacity: Double = 0.18,
        blurRadius: CGFloat = 6,
        smoothing: CGFloat = 0.22,
        material: Material = .thinMaterial
    ) {
        self.size = size
        self.magnification = magnification
        self.offset = offset
        self.edgePadding = edgePadding
        self.cornerRadius = cornerRadius ?? min(size.width, size.height) * 0.5
        self.borderWidth = borderWidth
        self.glassOpacity = glassOpacity
        self.highlightOpacity = highlightOpacity
        self.glowOpacity = glowOpacity
        self.blurRadius = blurRadius
        self.smoothing = smoothing
        self.material = material
    }

    static let `default` = LoupeConfiguration()
}

struct LoupeState {
    var isVisible: Bool = false
    var fingerLocation: CGPoint = .zero
    var loupeScreenPosition: CGPoint = .zero
    var magnification: CGFloat
    var loupeSize: CGSize

    init(configuration: LoupeConfiguration = .default) {
        magnification = configuration.magnification
        loupeSize = configuration.size
    }

    mutating func update(
        fingerLocation: CGPoint,
        in bounds: CGRect,
        configuration: LoupeConfiguration
    ) {
        magnification = configuration.magnification
        loupeSize = configuration.size

        let clampedFinger = fingerLocation.clamped(to: bounds)
        self.fingerLocation = clampedFinger

        let target = LoupeState.clampedLoupePosition(
            fingerLocation: fingerLocation,
            bounds: bounds,
            size: configuration.size,
            offset: configuration.offset,
            edgePadding: configuration.edgePadding
        )

        if !isVisible {
            isVisible = true
            loupeScreenPosition = target
            return
        }

        if configuration.smoothing > 0 {
            loupeScreenPosition = loupeScreenPosition.lerped(
                to: target,
                alpha: configuration.smoothing
            )
        } else {
            loupeScreenPosition = target
        }
    }

    mutating func hide() {
        isVisible = false
    }

    private static func clampedLoupePosition(
        fingerLocation: CGPoint,
        bounds: CGRect,
        size: CGSize,
        offset: CGSize,
        edgePadding: CGFloat
    ) -> CGPoint {
        let raw = CGPoint(
            x: fingerLocation.x + offset.width,
            y: fingerLocation.y + offset.height
        )

        let insetX = size.width * 0.5 + edgePadding
        let insetY = size.height * 0.5 + edgePadding
        let safeRect = bounds.insetBy(dx: insetX, dy: insetY)

        guard safeRect.width > 0, safeRect.height > 0 else {
            return CGPoint(x: bounds.midX, y: bounds.midY)
        }

        return raw.clamped(to: safeRect)
    }
}

private struct LoupeView<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @Binding var state: LoupeState
    let configuration: LoupeConfiguration
    let boardSize: CGSize
    let content: Content

    init(
        state: Binding<LoupeState>,
        configuration: LoupeConfiguration,
        boardSize: CGSize,
        @ViewBuilder content: () -> Content
    ) {
        _state = state
        self.configuration = configuration
        self.boardSize = boardSize
        self.content = content()
    }

    var body: some View {
        if state.isVisible {
            let shape = RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
            let scaledOffset = CGSize(
                width: state.loupeSize.width * 0.5 - state.fingerLocation.x * state.magnification,
                height: state.loupeSize.height * 0.5 - state.fingerLocation.y * state.magnification
            )

            ZStack {
                shape
                    .fill(HostDesignTokens.fillStyle(for: .loupe, reduceTransparency: reduceTransparency))
                    .opacity(configuration.glassOpacity)

                content
                    .frame(width: boardSize.width, height: boardSize.height)
                    .scaleEffect(state.magnification, anchor: .topLeading)
                    .offset(scaledOffset)
                    .frame(width: state.loupeSize.width, height: state.loupeSize.height, alignment: .topLeading)
                    .clipShape(shape)
            }
            .frame(width: state.loupeSize.width, height: state.loupeSize.height)
            .overlay(
                shape.stroke(
                    HostDesignTokens.strokeColor(for: colorSchemeContrast),
                    lineWidth: configuration.borderWidth
                )
            )
            .position(state.loupeScreenPosition)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}

private extension CGPoint {
    func lerped(to target: CGPoint, alpha: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (target.x - x) * alpha,
            y: y + (target.y - y) * alpha
        )
    }

    func clamped(to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(x, rect.minX), rect.maxX),
            y: min(max(y, rect.minY), rect.maxY)
        )
    }
}

private struct WordSearchGameView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let dayOffset: Int
    let todayOffset: Int
    let date: Date
    let puzzle: HostPuzzle
    let gridSize: Int
    let wordHintMode: HostWordHintMode
    let onProgressUpdate: () -> Void
    let sharedSync: HostSharedSyncContext?
    let onClose: (() -> Void)?

    @StateObject private var celebrationController = HostCelebrationController()
    @State private var foundWords: Set<String>
    @State private var solvedPositions: Set<HostGridPosition>
    @State private var startedAt: Date?
    @State private var endedAt: Date?
    @State private var activeSelection: [HostGridPosition] = []
    @State private var dragAnchor: HostGridPosition?
    @State private var selectionFeedback: HostSelectionFeedback?
    @State private var feedbackNonce = 0
    @State private var showResetAlert = false
    @State private var showEntryBoard = false
    @State private var showEntryBottom = false
    @State private var didRunEntry = false
    @State private var isCompletedOverlayVisible = false
    @State private var showCompletedBackdrop = false
    @State private var showCompletedToast = false
    @State private var completedStreakLabel: String?
    @State private var completionOverlayTask: Task<Void, Never>?

    init(
        dayOffset: Int,
        todayOffset: Int,
        date: Date,
        puzzle: HostPuzzle,
        gridSize: Int,
        wordHintMode: HostWordHintMode,
        initialProgress: HostAppProgressRecord?,
        sharedSync: HostSharedSyncContext?,
        onProgressUpdate: @escaping () -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.dayOffset = dayOffset
        self.todayOffset = todayOffset
        self.date = date
        self.puzzle = puzzle
        self.gridSize = gridSize
        self.wordHintMode = wordHintMode
        self.onProgressUpdate = onProgressUpdate
        self.sharedSync = sharedSync
        self.onClose = onClose

        let puzzleWords = Set(puzzle.words.map { $0.uppercased() })
        let storedFound = Set((initialProgress?.foundWords ?? []).map { $0.uppercased() })
        let normalizedFound = storedFound.intersection(puzzleWords)

        let maxRow = puzzle.grid.count
        let maxCol = puzzle.grid.first?.count ?? 0
        let storedPositions = initialProgress?.solvedPositions ?? []
        let normalizedPositions = storedPositions.compactMap { position -> HostGridPosition? in
            guard position.row >= 0, position.col >= 0, position.row < maxRow, position.col < maxCol else {
                return nil
            }
            return HostGridPosition(row: position.row, col: position.col)
        }

        _foundWords = State(initialValue: normalizedFound)
        _solvedPositions = State(initialValue: Set(normalizedPositions))
        _startedAt = State(initialValue: initialProgress?.startedDate)
        _endedAt = State(initialValue: initialProgress?.endedDate)
    }

    private var puzzleWords: [String] {
        puzzle.words.map { $0.uppercased() }
    }

    private var puzzleWordSet: Set<String> {
        Set(puzzleWords)
    }

    private var progressCount: Int {
        foundWords.intersection(puzzleWordSet).count
    }

    private var isCompleted: Bool {
        !puzzleWords.isEmpty && progressCount >= puzzleWords.count
    }

    var body: some View {
        ZStack {
            SoftGlowBackground()

            GeometryReader { geometry in
                let side = min(geometry.size.width - 32, 420)

                VStack(spacing: 16) {
                    WordSearchBoardView(
                        grid: puzzle.grid,
                        words: puzzle.words,
                        foundWords: foundWords,
                        solvedPositions: solvedPositions,
                        activePositions: activeSelection,
                        feedback: selectionFeedback,
                        celebrations: celebrationController.wordCelebrations,
                        sideLength: side
                    ) { position in
                        guard !isCompleted else { return }
                        handleDragChanged(position)
                    } onDragEnded: {
                        guard !isCompleted else { return }
                        handleDragEnded()
                    }
                    .opacity(showEntryBoard ? 1 : 0)
                    .scaleEffect(showEntryBoard ? 1 : 0.98)

                    objectivesView
                        .offset(y: showEntryBottom ? 0 : 24)
                        .opacity(showEntryBottom ? 1 : 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .allowsHitTesting(!isCompletedOverlayVisible)

            if isCompletedOverlayVisible {
                CompletionOverlayView(
                    showBackdrop: showCompletedBackdrop,
                    showToast: showCompletedToast,
                    streakLabel: completedStreakLabel,
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
        .navigationTitle(HostDateFormatter.monthDay(for: date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.down")
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showResetAlert = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Reiniciar reto")
            }
        }
        .onAppear {
            if startedAt == nil && !isCompleted {
                startedAt = Date()
                saveProgress()
            }
            runEntryTransition()
        }
        .onDisappear {
            completionOverlayTask?.cancel()
            completionOverlayTask = nil
        }
        .alert("Reiniciar reto", isPresented: $showResetAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Reiniciar", role: .destructive) {
                resetProgress()
            }
        } message: {
            Text("Se borrara el progreso de este dia.")
        }
    }

    private var objectivesView: some View {
        PuzzleWordsPreview(
            words: puzzle.words,
            foundWords: foundWords,
            displayMode: wordHintMode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func handleDragChanged(_ position: HostGridPosition) {
        if dragAnchor == nil {
            dragAnchor = position
            activeSelection = [position]
            if startedAt == nil && !isCompleted {
                startedAt = Date()
                saveProgress()
            }
            return
        }

        guard let anchor = dragAnchor else { return }
        let direction = snappedDirection(from: anchor, to: position)
        activeSelection = selectionPath(from: anchor, to: position, direction: direction)
    }

    private func handleDragEnded() {
        let selection = activeSelection
        dragAnchor = nil
        activeSelection = []
        guard selection.count >= 2 else { return }
        finalizeSelection(selection)
    }

    private func snappedDirection(from start: HostGridPosition, to end: HostGridPosition) -> (Int, Int) {
        let drRaw = end.row - start.row
        let dcRaw = end.col - start.col
        guard drRaw != 0 || dcRaw != 0 else { return (0, 0) }
        if drRaw == 0 && dcRaw == 0 {
            return (0, 0)
        }
        let angle = atan2(Double(drRaw), Double(dcRaw))
        let octant = Int(round(angle / (.pi / 4)))
        let index = (octant + 8) % 8
        let directions: [(Int, Int)] = [
            (0, 1), (1, 1), (1, 0), (1, -1),
            (0, -1), (-1, -1), (-1, 0), (-1, 1)
        ]
        return directions[index]
    }

    private func selectionPath(
        from start: HostGridPosition,
        to end: HostGridPosition,
        direction: (Int, Int)
    ) -> [HostGridPosition] {
        let drRaw = end.row - start.row
        let dcRaw = end.col - start.col
        let steps = max(abs(drRaw), abs(dcRaw))
        let rows = puzzle.grid.count
        let cols = puzzle.grid.first?.count ?? 0

        guard steps >= 0 else { return [start] }

        return (0...steps).compactMap { step in
            let r = start.row + direction.0 * step
            let c = start.col + direction.1 * step
            guard r >= 0, c >= 0, r < rows, c < cols else { return nil }
            return HostGridPosition(row: r, col: c)
        }
    }

    private func finalizeSelection(_ positions: [HostGridPosition]) {
        let selectedWord = positions.map { puzzle.grid[$0.row][$0.col] }.joined().uppercased()
        let reversed = String(selectedWord.reversed())

        let match: String?
        if puzzleWordSet.contains(selectedWord) {
            match = selectedWord
        } else if puzzleWordSet.contains(reversed) {
            match = reversed
        } else {
            match = nil
        }

        guard let matched = match else {
            showFeedback(kind: .incorrect, positions: positions)
            return
        }
        guard !foundWords.contains(matched) else {
            showFeedback(kind: .incorrect, positions: positions)
            return
        }

        foundWords.insert(matched)
        solvedPositions.formUnion(positions)
        showFeedback(kind: .correct, positions: positions)

        let completedNow = isCompleted && endedAt == nil
        var completionStreak: Int?
        if completedNow {
            endedAt = Date()
            HostCompletionStore.markCompleted(dayOffset: dayOffset)
            if dayOffset == todayOffset {
                let streakState = HostStreakStore.markCompleted(dayOffset: dayOffset, todayOffset: todayOffset)
                completionStreak = streakState.current
                _ = HostHintStore.rewardCompletion(dayOffset: dayOffset, todayOffset: todayOffset)
            }
        }

        onWordValidated(wordId: matched, wordText: matched, pathCells: positions, isPuzzleComplete: completedNow)
        saveProgress()
        if completedNow {
            let preferences = HostCelebrationSettings.preferences()
            presentCompletionOverlay(streakCount: completionStreak, preferences: preferences)
        }
    }

    private func saveProgress() {
        let record = HostAppProgressRecord(
            dayOffset: dayOffset,
            gridSize: gridSize,
            foundWords: Array(foundWords),
            solvedPositions: solvedPositions.map { HostAppProgressPosition(row: $0.row, col: $0.col) },
            startedAt: startedAt?.timeIntervalSince1970,
            endedAt: endedAt?.timeIntervalSince1970
        )
        if let sharedSync {
            HostSharedPuzzleStateStore.updateProgress(
                puzzleIndex: sharedSync.puzzleIndex,
                gridSize: gridSize,
                foundWords: foundWords,
                solvedPositions: solvedPositions
            )
        } else {
            HostAppProgressStore.save(record)
        }
        onProgressUpdate()
    }

    private func resetProgress() {
        completionOverlayTask?.cancel()
        completionOverlayTask = nil
        isCompletedOverlayVisible = false
        showCompletedBackdrop = false
        showCompletedToast = false
        completedStreakLabel = nil
        foundWords = []
        solvedPositions = []
        activeSelection = []
        dragAnchor = nil
        startedAt = nil
        endedAt = nil
        if let sharedSync {
            HostSharedPuzzleStateStore.clearProgress(
                puzzleIndex: sharedSync.puzzleIndex,
                gridSize: gridSize
            )
        } else {
            HostAppProgressStore.reset(dayOffset: dayOffset, gridSize: gridSize)
        }
        onProgressUpdate()
    }

    private func runEntryTransition() {
        guard !didRunEntry else { return }
        didRunEntry = true

        if reduceMotion {
            showEntryBoard = true
            showEntryBottom = true
            return
        }

        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.22)) {
                showEntryBoard = true
            }
            try? await Task.sleep(nanoseconds: 90_000_000)
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                showEntryBottom = true
            }
        }
    }

    private func showFeedback(kind: HostSelectionFeedbackKind, positions: [HostGridPosition]) {
        feedbackNonce += 1
        let currentNonce = feedbackNonce
        withAnimation(.easeOut(duration: 0.2)) {
            selectionFeedback = HostSelectionFeedback(kind: kind, positions: positions)
        }

        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard currentNonce == feedbackNonce else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectionFeedback = nil
                }
            }
        }
    }

    private func onWordValidated(
        wordId: String,
        wordText: String,
        pathCells: [HostGridPosition],
        isPuzzleComplete: Bool
    ) {
        _ = wordText
        let anchor = HostWordPathFinder.anchorUnit(for: pathCells, in: puzzle.grid)
        let preferences = HostCelebrationSettings.preferences()
        celebrationController.celebrateWord(
            wordId: wordId,
            pathCells: pathCells,
            anchorPoint: anchor,
            intensity: preferences.intensity,
            preferences: preferences,
            reduceMotion: reduceMotion
        )
        _ = isPuzzleComplete
    }

    private func presentCompletionOverlay(streakCount: Int?, preferences: HostCelebrationPreferences) {
        completionOverlayTask?.cancel()
        completedStreakLabel = streakCount.map { "Racha \($0)" }
        isCompletedOverlayVisible = true
        showCompletedToast = false

        if preferences.enableHaptics {
            HostHaptics.completionSuccess()
        }
        if preferences.enableSound {
            HostSoundPlayer.play(.completion)
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            showCompletedBackdrop = true
        }

        completionOverlayTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.16) : .easeOut(duration: 0.2)) {
                showCompletedToast = true
            }

            try? await Task.sleep(nanoseconds: 1_500_000_000)
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

        withAnimation(.easeInOut(duration: 0.14)) {
            showCompletedToast = false
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        withAnimation(.easeInOut(duration: 0.1)) {
            showCompletedBackdrop = false
        }

        try? await Task.sleep(nanoseconds: 110_000_000)

        isCompletedOverlayVisible = false
        completedStreakLabel = nil
        if !cancelScheduledTask {
            completionOverlayTask = nil
        }
    }
}

private struct WordSearchBoardView: View {
    let grid: [[String]]
    let words: [String]
    let foundWords: Set<String>
    let solvedPositions: Set<HostGridPosition>
    let activePositions: [HostGridPosition]
    let feedback: HostSelectionFeedback?
    let celebrations: [HostWordCelebration]
    let sideLength: CGFloat
    let onDragChanged: (HostGridPosition) -> Void
    let onDragEnded: () -> Void
    @State private var loupeState = LoupeState(configuration: .default)

    private let loupeConfiguration = LoupeConfiguration.default

    private struct WordOutline: Identifiable {
        let id: String
        let positions: [HostGridPosition]
    }

    private let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]

    private var rows: Int { grid.count }
    private var cols: Int { grid.first?.count ?? 0 }

    var body: some View {
        let safeRows = max(rows, 1)
        let safeCols = max(cols, 1)
        let cellSize = sideLength / CGFloat(safeCols)
        let activeSet = Set(activePositions)
        let boardBounds = CGRect(origin: .zero, size: CGSize(width: sideLength, height: sideLength))

        boardLayer(
            cellSize: cellSize,
            safeRows: safeRows,
            safeCols: safeCols,
            activeSet: activeSet
        )
        .frame(width: sideLength, height: sideLength)
        .contentShape(Rectangle())
        .overlay(alignment: .topLeading) {
            // Magnify the board content directly to avoid per-frame screenshots.
            LoupeView(
                state: $loupeState,
                configuration: loupeConfiguration,
                boardSize: CGSize(width: sideLength, height: sideLength)
            ) {
                boardLayer(
                    cellSize: cellSize,
                    safeRows: safeRows,
                    safeCols: safeCols,
                    activeSet: activeSet
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    loupeState.update(
                        fingerLocation: value.location,
                        in: boardBounds,
                        configuration: loupeConfiguration
                    )
                    if let position = position(for: value.location, cellSize: cellSize) {
                        onDragChanged(position)
                    }
                }
                .onEnded { _ in
                    loupeState.hide()
                    onDragEnded()
                }
        )
    }

    @ViewBuilder
    private func boardLayer(
        cellSize: CGFloat,
        safeRows: Int,
        safeCols: Int,
        activeSet: Set<HostGridPosition>
    ) -> some View {
        let boardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        ZStack {
            boardShape
                .fill(Color.white)

            VStack(spacing: 0) {
                ForEach(0..<safeRows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<safeCols, id: \.self) { col in
                            let position = HostGridPosition(row: row, col: col)
                            let letter = row < rows && col < cols ? grid[row][col] : ""
                            let isActive = activeSet.contains(position)

                            Text(letter)
                                .font(.system(size: max(10, cellSize * 0.45), weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .frame(width: cellSize, height: cellSize)
                                .background(cellFill(isActive: isActive))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .clipShape(boardShape)

            foundWordOutlines(cellSize: cellSize)
                .allowsHitTesting(false)

            celebrationLayer(cellSize: cellSize)
                .allowsHitTesting(false)

            if let first = activePositions.first, let last = activePositions.last, activePositions.count > 1 {
                selectionCapsule(from: first, to: last, cellSize: cellSize)
            }

            if let feedback {
                feedbackCapsule(feedback, cellSize: cellSize)
                    .transition(.opacity)
            }
        }
        .compositingGroup()
        .clipShape(boardShape)
        .overlay(
            boardShape
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }

    private func cellFill(isActive: Bool) -> Color {
        if isActive {
            return Color.accentColor.opacity(0.22)
        }
        return .white
    }

    private func selectionCapsule(from start: HostGridPosition, to end: HostGridPosition, cellSize: CGFloat) -> some View {
        let startPoint = center(for: start, cellSize: cellSize)
        let endPoint = center(for: end, cellSize: cellSize)
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let angle = Angle(radians: atan2(dy, dx))
        let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
        let capsuleHeight = cellSize * 0.82
        let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

        return Capsule(style: .continuous)
            .fill(Color.accentColor.opacity(0.2))
            .frame(width: capsuleWidth, height: capsuleHeight)
            .rotationEffect(angle)
            .position(centerPoint)
    }

    @ViewBuilder
    private func feedbackCapsule(_ feedback: HostSelectionFeedback, cellSize: CGFloat) -> some View {
        if let first = feedback.positions.first, let last = feedback.positions.last {
            let startPoint = center(for: first, cellSize: cellSize)
            let endPoint = center(for: last, cellSize: cellSize)
            let capsuleHeight = cellSize * 0.82
            let lineWidth = max(1.8, min(3.6, cellSize * 0.12))
            let color = feedback.kind == .correct ? Color.green : Color.red

            StretchingFeedbackCapsule(
                start: startPoint,
                end: endPoint,
                capsuleHeight: capsuleHeight,
                lineWidth: lineWidth,
                color: color
            )
        }
    }

    private func celebrationLayer(cellSize: CGFloat) -> some View {
        let boardSize = cellSize * CGFloat(max(cols, 1))

        return ZStack {
            ForEach(celebrations) { celebration in
                CelebrationGlowCapsule(
                    positions: celebration.positions,
                    cellSize: cellSize,
                    duration: celebration.popDuration,
                    reduceMotion: celebration.reduceMotion
                )
            }

            ForEach(celebrations.filter { $0.showsParticles }) { celebration in
                let anchor = CGPoint(
                    x: celebration.anchorUnit.x * boardSize,
                    y: celebration.anchorUnit.y * boardSize
                )
                ParticleBurstView(
                    burstID: celebration.id,
                    anchorPoint: anchor,
                    intensity: celebration.intensity,
                    duration: celebration.particleDuration,
                    reduceMotion: celebration.reduceMotion
                )
                .frame(width: boardSize, height: boardSize)
            }
        }
    }

    private func foundWordOutlines(cellSize: CGFloat) -> some View {
        let capsuleHeight = cellSize * 0.82
        let lineWidth = max(1.5, min(3.0, cellSize * 0.10))

        return ZStack {
            ForEach(solvedWordOutlines) { outline in
                outlineShape(
                    for: outline.positions,
                    cellSize: cellSize,
                    capsuleHeight: capsuleHeight,
                    lineWidth: lineWidth
                )
            }
        }
    }

    @ViewBuilder
    private func outlineShape(
        for positions: [HostGridPosition],
        cellSize: CGFloat,
        capsuleHeight: CGFloat,
        lineWidth: CGFloat
    ) -> some View {
        if let first = positions.first, let last = positions.last {
            let startPoint = center(for: first, cellSize: cellSize)
            let endPoint = center(for: last, cellSize: cellSize)
            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let angle = Angle(radians: atan2(dy, dx))
            let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
            let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

            Capsule(style: .continuous)
                .fill(Color.accentColor.opacity(0.14))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.accentColor.opacity(0.85), lineWidth: lineWidth)
                )
                .frame(width: capsuleWidth, height: capsuleHeight)
                .rotationEffect(angle)
                .position(centerPoint)
        }
    }

    private var solvedWordOutlines: [WordOutline] {
        let normalizedFound = Set(foundWords.map { $0.uppercased() })

        return words.enumerated().compactMap { index, rawWord in
            let word = rawWord.uppercased()
            guard normalizedFound.contains(word) else { return nil }
            guard let path = bestPath(for: word) else { return nil }
            let signature = path.map { "\($0.row)-\($0.col)" }.joined(separator: "_")
            return WordOutline(
                id: "\(index)-\(word)-\(signature)",
                positions: path
            )
        }
    }

    private func bestPath(for word: String) -> [HostGridPosition]? {
        let candidates = candidatePaths(for: word)
        guard !candidates.isEmpty else { return nil }
        return candidates.max { pathScore($0) < pathScore($1) }
    }

    private func pathScore(_ path: [HostGridPosition]) -> Int {
        path.reduce(0) { partial, position in
            partial + (solvedPositions.contains(position) ? 1 : 0)
        }
    }

    private func candidatePaths(for word: String) -> [[HostGridPosition]] {
        let upperWord = word.uppercased()
        let letters = upperWord.map { String($0) }
        let reversed = Array(letters.reversed())
        let rowCount = grid.count
        let colCount = grid.first?.count ?? 0

        guard !letters.isEmpty else { return [] }
        guard rowCount > 0, colCount > 0 else { return [] }

        var results: [[HostGridPosition]] = []

        for row in 0..<rowCount {
            for col in 0..<colCount {
                for (dr, dc) in directions {
                    var path: [HostGridPosition] = []
                    var collected: [String] = []
                    var isValid = true

                    for step in 0..<letters.count {
                        let r = row + step * dr
                        let c = col + step * dc
                        if r < 0 || c < 0 || r >= rowCount || c >= colCount {
                            isValid = false
                            break
                        }
                        path.append(HostGridPosition(row: r, col: c))
                        collected.append(grid[r][c].uppercased())
                    }

                    guard isValid else { continue }
                    if collected == letters || collected == reversed {
                        results.append(path)
                    }
                }
            }
        }

        return results
    }

    private func center(for position: HostGridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }

    private func position(for location: CGPoint, cellSize: CGFloat) -> HostGridPosition? {
        let row = Int(location.y / cellSize)
        let col = Int(location.x / cellSize)
        guard row >= 0, col >= 0, row < rows, col < cols else { return nil }
        return HostGridPosition(row: row, col: col)
    }
}

private struct StretchingFeedbackCapsule: View {
    let start: CGPoint
    let end: CGPoint
    let capsuleHeight: CGFloat
    let lineWidth: CGFloat
    let color: Color

    @State private var animate = false

    var body: some View {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = Angle(radians: atan2(dy, dx))
        let centerPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

        return Capsule(style: .continuous)
            .stroke(color, lineWidth: lineWidth)
            .frame(width: capsuleWidth, height: capsuleHeight)
            .scaleEffect(x: animate ? 1 : 0.05, y: 1, anchor: .leading)
            .rotationEffect(angle)
            .position(centerPoint)
            .onAppear {
                withAnimation(.easeOut(duration: 0.22)) {
                    animate = true
                }
            }
    }
}

private struct CelebrationGlowCapsule: View {
    let positions: [HostGridPosition]
    let cellSize: CGFloat
    let duration: TimeInterval
    let reduceMotion: Bool

    @State private var animate = false

    var body: some View {
        let capsuleHeight = cellSize * 0.82
        let lineWidth = max(1.8, min(3.8, cellSize * 0.12))

        guard let first = positions.first, let last = positions.last else {
            return AnyView(EmptyView())
        }

        let startPoint = center(for: first, cellSize: cellSize)
        let endPoint = center(for: last, cellSize: cellSize)
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let angle = Angle(radians: atan2(dy, dx))
        let centerPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
        let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

        let view = Capsule(style: .continuous)
            .stroke(Color.green.opacity(0.85), lineWidth: lineWidth)
            .shadow(color: Color.green.opacity(animate ? 0.55 : 0.0), radius: animate ? 10 : 2)
            .frame(width: capsuleWidth, height: capsuleHeight)
            .scaleEffect(reduceMotion ? 1.0 : (animate ? 1.03 : 0.92))
            .opacity(animate ? 1 : 0)
            .rotationEffect(angle)
            .position(centerPoint)
            .onAppear {
                if reduceMotion {
                    animate = true
                } else {
                    withAnimation(.easeOut(duration: duration)) {
                        animate = true
                    }
                }
            }

        return AnyView(view)
    }

    private func center(for position: HostGridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }
}

private struct ParticleBurstView: UIViewRepresentable {
    let burstID: UUID
    let anchorPoint: CGPoint
    let intensity: HostCelebrationIntensity
    let duration: TimeInterval
    let reduceMotion: Bool

    func makeUIView(context: Context) -> ParticleBurstUIView {
        ParticleBurstUIView()
    }

    func updateUIView(_ uiView: ParticleBurstUIView, context: Context) {
        uiView.burst(
            id: burstID,
            anchorPoint: anchorPoint,
            intensity: intensity,
            duration: duration,
            reduceMotion: reduceMotion
        )
    }
}

private final class ParticleBurstUIView: UIView {
    private let emitter = CAEmitterLayer()
    private var lastBurstID: UUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        emitter.emitterShape = .circle
        emitter.renderMode = .additive
        layer.addSublayer(emitter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.frame = bounds
    }

    func burst(
        id: UUID,
        anchorPoint: CGPoint,
        intensity: HostCelebrationIntensity,
        duration: TimeInterval,
        reduceMotion: Bool
    ) {
        guard lastBurstID != id else { return }
        lastBurstID = id

        guard !reduceMotion else {
            emitter.birthRate = 0
            return
        }

        emitter.emitterPosition = anchorPoint
        emitter.emitterSize = CGSize(width: 12, height: 12)
        emitter.beginTime = CACurrentMediaTime()
        emitter.emitterCells = HostParticleFactory.wordCells(intensity: intensity, duration: duration)
        emitter.birthRate = 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.emitter.birthRate = 0
        }
    }
}

private struct ConfettiView: UIViewRepresentable {
    let burstID: UUID
    let duration: TimeInterval
    let reduceMotion: Bool

    func makeUIView(context: Context) -> ConfettiUIView {
        ConfettiUIView()
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {
        uiView.trigger(id: burstID, duration: duration, reduceMotion: reduceMotion)
    }
}

private final class ConfettiUIView: UIView {
    private let emitter = CAEmitterLayer()
    private var lastBurstID: UUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        emitter.emitterShape = .line
        emitter.emitterMode = .outline
        emitter.renderMode = .unordered
        layer.addSublayer(emitter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.frame = bounds
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -8)
    }

    func trigger(id: UUID, duration: TimeInterval, reduceMotion: Bool) {
        guard lastBurstID != id else { return }
        lastBurstID = id

        guard !reduceMotion else {
            emitter.birthRate = 0
            return
        }

        emitter.beginTime = CACurrentMediaTime()
        emitter.emitterCells = HostParticleFactory.confettiCells(duration: duration)
        emitter.birthRate = 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.emitter.birthRate = 0
        }
    }
}

private struct CompletionOverlayView: View {
    let showBackdrop: Bool
    let showToast: Bool
    let streakLabel: String?
    let reduceMotion: Bool
    let reduceTransparency: Bool
    let onTapDismiss: () -> Void

    private var toastTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96))
    }

    var body: some View {
        ZStack {
            if showBackdrop {
                Rectangle()
                    .fill(
                        reduceTransparency
                        ? AnyShapeStyle(Color(.systemBackground).opacity(0.88))
                        : AnyShapeStyle(.regularMaterial)
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)

                Color.black.opacity(0.12)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if showToast {
                CompletionGlassToast(
                    streakLabel: streakLabel,
                    reduceTransparency: reduceTransparency
                )
                .transition(toastTransition)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTapDismiss()
        }
    }
}

private struct CompletionGlassToast: View {
    let streakLabel: String?
    let reduceTransparency: Bool

    private var accessibilityText: String {
        if let streakLabel {
            return "Completado. \(streakLabel)"
        }
        return "Completado"
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        reduceTransparency
                        ? AnyShapeStyle(Color(.secondarySystemBackground))
                        : AnyShapeStyle(.thinMaterial)
                    )
                    .frame(width: 54, height: 54)

                Circle()
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    .frame(width: 54, height: 54)

                Image(systemName: "checkmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
            }

            Text("Completado")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            if let streakLabel {
                Text(streakLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    reduceTransparency
                    ? AnyShapeStyle(Color(.secondarySystemBackground))
                    : AnyShapeStyle(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
}

private enum HostParticleFactory {
    private static let sparkleImages: [CGImage] = [
        makeCircleImage(color: UIColor.systemGreen),
        makeCircleImage(color: UIColor.systemGreen),
        makeCircleImage(color: UIColor.systemBlue)
    ]

    private static let confettiImages: [CGImage] = [
        makeRectImage(color: UIColor.systemGreen),
        makeRectImage(color: UIColor.systemBlue),
        makeRectImage(color: UIColor.systemGreen),
        makeRectImage(color: UIColor.systemGreen)
    ]

    static func wordCells(intensity: HostCelebrationIntensity, duration: TimeInterval) -> [CAEmitterCell] {
        let birthRate = intensity.particleBirthRate
        let velocity = intensity.particleVelocity
        let scale = intensity.particleScale

        return sparkleImages.map { image in
            let cell = CAEmitterCell()
            cell.contents = image
            cell.birthRate = birthRate
            cell.lifetime = Float(duration)
            cell.velocity = velocity
            cell.velocityRange = velocity * 0.45
            cell.emissionRange = .pi * 2
            cell.scale = scale
            cell.scaleRange = scale * 0.4
            cell.alphaSpeed = -1.2
            cell.spinRange = .pi
            return cell
        }
    }

    static func confettiCells(duration: TimeInterval) -> [CAEmitterCell] {
        return confettiImages.map { image in
            let cell = CAEmitterCell()
            cell.contents = image
            cell.birthRate = 10
            cell.lifetime = Float(duration)
            cell.velocity = 180
            cell.velocityRange = 60
            cell.yAcceleration = 120
            cell.emissionRange = .pi / 6
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.spinRange = .pi
            cell.alphaSpeed = -0.9
            return cell
        }
    }

    private static func makeCircleImage(color: UIColor) -> CGImage {
        let size = CGSize(width: 6, height: 6)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fillEllipse(in: rect)
        }
        if let cgImage = image.cgImage {
            return cgImage
        }
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }.cgImage!
    }

    private static func makeRectImage(color: UIColor) -> CGImage {
        let size = CGSize(width: 6, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fill(rect)
        }
        if let cgImage = image.cgImage {
            return cgImage
        }
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }.cgImage!
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var installDate = HostPuzzleCalendar.installationDate()
    @State private var selectedOffset: Int?
    @State private var presentedGame: HostPresentedGame?
    @State private var launchingCardOffset: Int?
    @State private var easterTapCounts: [Int: Int] = [:]
    @State private var easterUnlockedOffsets: Set<Int> = []
    @State private var gridSize = HostDifficultySettings.gridSize()
    @State private var appearanceMode = HostAppearanceSettings.mode()
    @State private var wordHintMode = HostWordHintSettings.mode()
    @State private var sharedState = HostSharedPuzzleStateStore.loadState(
        now: Date(),
        preferredGridSize: HostDifficultySettings.gridSize()
    )
    @State private var appProgressRecords = HostAppProgressStore.loadRecords()
    @State private var completedOffsets = HostCompletionStore.load()
    @State private var streakCount = 0

    private var todayOffset: Int {
        let boundary = HostSharedPuzzleStateStore.currentRotationBoundary(for: Date())
        return HostPuzzleCalendar.dayOffset(from: installDate, to: boundary)
    }

    private var minOffset: Int { 0 }
    private var maxOffset: Int { todayOffset + 1 }

    private var carouselOffsets: [Int] {
        Array(minOffset...maxOffset)
    }

    private func puzzleDate(for offset: Int) -> Date {
        let boundary = HostSharedPuzzleStateStore.currentRotationBoundary(for: Date())
        let delta = offset - todayOffset
        return Calendar.current.date(byAdding: .day, value: delta, to: boundary) ?? boundary
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoftGlowBackground()

                GeometryReader { geometry in
                    let verticalInset: CGFloat = 40
                    let interSectionSpacing: CGFloat = 40
                    let dayCarouselHeight: CGFloat = 92
                    let cardWidth = min(geometry.size.width * 0.80, 450)
                    let sidePadding = max((geometry.size.width - cardWidth) / 2, 10)
                    let availableCardHeight = geometry.size.height - dayCarouselHeight - interSectionSpacing - (verticalInset * 2)
                    let cardHeight = min(max(availableCardHeight, 260), 620)
                    let cardSelection = Binding<Int?>(
                        get: {
                            let current = selectedOffset ?? todayOffset
                            return carouselOffsets.contains(current) ? current : nil
                        },
                        set: { selectedOffset = $0 }
                    )

                    VStack(spacing: interSectionSpacing) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 14) {
                                ForEach(carouselOffsets, id: \.self) { offset in
                                    let date = puzzleDate(for: offset)
                                    let puzzle = puzzleForOffset(offset)
                                    let progress = progressForOffset(offset, puzzle: puzzle)
                                    let isLocked = offset > todayOffset && !easterUnlockedOffsets.contains(offset)
                                    let hoursLeft = hoursUntilAvailable(for: offset)

                                    DailyChallengeCard(
                                        date: date,
                                        puzzle: puzzle,
                                        progress: progress,
                                        isLocked: isLocked,
                                        hoursUntilAvailable: hoursLeft,
                                        isLaunching: launchingCardOffset == offset
                                    ) {
                                        handleChallengeCardTap(offset: offset, isLocked: isLocked)
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

                        DayCarouselView(
                            offsets: carouselOffsets,
                            selectedOffset: $selectedOffset,
                            todayOffset: todayOffset,
                            unlockedOffsets: easterUnlockedOffsets,
                            completedOffsets: completedOffsets,
                            dateForOffset: { puzzleDate(for: $0) }
                        ) { offset in
                            hoursUntilAvailable(for: offset)
                        }
                        .frame(height: dayCarouselHeight)
                        .padding(.horizontal, 20)
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
                            .font(.title3.weight(.semibold))
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HomeNavCounter(
                            value: completedOffsets.count,
                            systemImage: "checkmark.seal.fill",
                            tint: .black,
                            accessibilityLabel: "Retos completados \(completedOffsets.count)"
                        )
                        HomeNavCounter(
                            value: streakCount,
                            systemImage: "flame.fill",
                            tint: .black,
                            accessibilityLabel: "Racha actual \(streakCount)"
                        )
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Abrir ajustes")
                    }
                }
            }
            .onAppear {
                installDate = HostPuzzleCalendar.installationDate()
                gridSize = HostDifficultySettings.gridSize()
                appearanceMode = HostAppearanceSettings.mode()
                wordHintMode = HostWordHintSettings.mode()
                refreshAppProgress()
                selectedOffset = todayOffset
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                installDate = HostPuzzleCalendar.installationDate()
                gridSize = HostDifficultySettings.gridSize()
                appearanceMode = HostAppearanceSettings.mode()
                wordHintMode = HostWordHintSettings.mode()
                refreshAppProgress()
            }
            .onChange(of: selectedOffset) { _, value in
                guard let value else { return }
                if value > maxOffset {
                    selectedOffset = maxOffset
                }
            }
            .sheet(isPresented: $showSettings) {
                DifficultySettingsView(
                    currentGridSize: gridSize,
                    currentAppearanceMode: appearanceMode,
                    currentWordHintMode: wordHintMode
                ) { newGridSize, newAppearanceMode, newWordHintMode, celebrationPreferences in
                    let clamped = HostDifficultySettings.clampGridSize(newGridSize)

                    if clamped != gridSize {
                        gridSize = clamped
                        HostMaintenance.applyGridSize(clamped)
                    }

                    if newAppearanceMode != appearanceMode {
                        appearanceMode = newAppearanceMode
                        HostMaintenance.applyAppearance(newAppearanceMode)
                    }

                    if newWordHintMode != wordHintMode {
                        wordHintMode = newWordHintMode
                        HostMaintenance.applyWordHintMode(newWordHintMode)
                    }

                    HostCelebrationSettings.apply(preferences: celebrationPreferences)
                    refreshAppProgress()
                }
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private func puzzleForOffset(_ offset: Int) -> HostPuzzle {
        if offset == todayOffset, !sharedState.grid.isEmpty, !sharedState.words.isEmpty {
            return HostPuzzle(
                number: sharedState.puzzleIndex + 1,
                grid: sharedState.grid,
                words: sharedState.words
            )
        }
        return HostPuzzleCalendar.puzzle(forDayOffset: offset, gridSize: gridSize)
    }

    private func progressForOffset(_ offset: Int, puzzle: HostPuzzle) -> HostPuzzleProgress {
        if offset == todayOffset {
            return sharedState.progress(for: puzzle)
        }
        if let record = appProgressRecord(for: offset) {
            return record.progress(for: puzzle)
        }
        return .empty
    }

    private func appProgressRecord(for offset: Int) -> HostAppProgressRecord? {
        let key = HostAppProgressStore.key(for: offset, gridSize: gridSize)
        return appProgressRecords[key]
    }

    private func refreshAppProgress() {
        sharedState = HostSharedPuzzleStateStore.loadState(
            now: Date(),
            preferredGridSize: gridSize
        )
        appProgressRecords = HostAppProgressStore.loadRecords()
        completedOffsets = HostCompletionStore.load()

        if sharedState.isCompleted {
            HostCompletionStore.markCompleted(dayOffset: todayOffset)
            _ = HostStreakStore.markCompleted(dayOffset: todayOffset, todayOffset: todayOffset)
            _ = HostHintStore.rewardCompletion(dayOffset: todayOffset, todayOffset: todayOffset)
            completedOffsets = HostCompletionStore.load()
        }

        refreshGamification()
    }

    private func refreshGamification() {
        let streakState = HostStreakStore.refresh(todayOffset: todayOffset)
        streakCount = streakState.current
    }

    private func hoursUntilAvailable(for offset: Int) -> Int? {
        guard offset > todayOffset else { return nil }
        let availableAt = puzzleDate(for: offset)
        let remaining = availableAt.timeIntervalSince(Date())
        if remaining <= 0 {
            return 0
        }
        return Int(ceil(remaining / 3600))
    }

    @ViewBuilder
    private func gameOverlay(for offset: Int) -> some View {
        let puzzle = puzzleForOffset(offset)
        let record = offset == todayOffset
            ? sharedState.asAppRecord(dayOffset: offset, gridSize: gridSize)
            : appProgressRecord(for: offset)

        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            WordSearchGameView(
                dayOffset: offset,
                todayOffset: todayOffset,
                date: puzzleDate(for: offset),
                puzzle: puzzle,
                gridSize: gridSize,
                wordHintMode: wordHintMode,
                initialProgress: record,
                sharedSync: offset == todayOffset
                    ? HostSharedSyncContext(puzzleIndex: sharedState.puzzleIndex)
                    : nil,
                onProgressUpdate: {
                    refreshAppProgress()
                },
                onClose: {
                    closePresentedGame()
                }
            )
        }
    }

    private func closePresentedGame() {
        withAnimation(.easeInOut(duration: 0.22)) {
            presentedGame = nil
        }
    }

    private func presentGameFromCard(offset: Int, isLocked: Bool) {
        guard !isLocked else { return }
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

    private func handleChallengeCardTap(offset: Int, isLocked: Bool) {
        if !isLocked {
            presentGameFromCard(offset: offset, isLocked: false)
            return
        }

        let nextCount = (easterTapCounts[offset] ?? 0) + 1
        easterTapCounts[offset] = nextCount

        guard nextCount >= 10 else { return }
        easterUnlockedOffsets.insert(offset)
        easterTapCounts[offset] = 0
    }

}

private struct PuzzleGridPreview: View {
    let grid: [[String]]
    let words: [String]
    let foundWords: Set<String>
    let solvedPositions: Set<HostGridPosition>
    let sideLength: CGFloat
    
    private struct WordOutline: Identifiable {
        let id: String
        let positions: [HostGridPosition]
    }

    private let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]

    var body: some View {
        let size = max(grid.count, 1)
        let cellSize = sideLength / CGFloat(size)
        let fontSize = max(8, min(24, cellSize * 0.48))
        let gridShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return ZStack {
            VStack(spacing: 0) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<size, id: \.self) { col in
                            let value = row < grid.count && col < grid[row].count ? grid[row][col] : ""
                            let position = HostGridPosition(row: row, col: col)
                            Text(value)
                                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                                .frame(width: cellSize, height: cellSize)
                                .background(
                                    solvedPositions.contains(position) ? Color.accentColor.opacity(0.16) : .clear
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.23), lineWidth: 1)
                                )
                        }
                    }
                }
            }

            foundWordOutlines(cellSize: cellSize)
        }
        .frame(width: sideLength, height: sideLength, alignment: .center)
        .clipShape(gridShape)
        .overlay(
            gridShape
                .stroke(Color.gray.opacity(0.28), lineWidth: 1)
        )
    }

    private func foundWordOutlines(cellSize: CGFloat) -> some View {
        let capsuleHeight = cellSize * 0.82
        let lineWidth = max(1.5, min(3.0, cellSize * 0.10))

        return ZStack {
            ForEach(solvedWordOutlines) { outline in
                outlineShape(
                    for: outline.positions,
                    cellSize: cellSize,
                    capsuleHeight: capsuleHeight,
                    lineWidth: lineWidth
                )
            }
        }
    }

    @ViewBuilder
    private func outlineShape(
        for positions: [HostGridPosition],
        cellSize: CGFloat,
        capsuleHeight: CGFloat,
        lineWidth: CGFloat
    ) -> some View {
        if let first = positions.first, let last = positions.last {
            let start = center(for: first, cellSize: cellSize)
            let end = center(for: last, cellSize: cellSize)
            let dx = end.x - start.x
            let dy = end.y - start.y
            let angle = Angle(radians: atan2(dy, dx))
            let centerPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            let capsuleWidth = max(capsuleHeight, hypot(dx, dy) + capsuleHeight)

            Capsule(style: .continuous)
                .stroke(Color.accentColor.opacity(0.86), lineWidth: lineWidth)
                .frame(width: capsuleWidth, height: capsuleHeight)
                .rotationEffect(angle)
                .position(centerPoint)
        }
    }

    private func center(for position: HostGridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(position.col) * cellSize + cellSize / 2,
            y: CGFloat(position.row) * cellSize + cellSize / 2
        )
    }

    private var solvedWordOutlines: [WordOutline] {
        let normalizedFoundWords = Set(foundWords.map { $0.uppercased() })

        return words.enumerated().compactMap { index, rawWord in
            let word = rawWord.uppercased()
            guard normalizedFoundWords.contains(word) else { return nil }
            guard let path = bestPath(for: word) else { return nil }
            let signature = path.map { "\($0.row)-\($0.col)" }.joined(separator: "_")
            return WordOutline(
                id: "\(index)-\(word)-\(signature)",
                positions: path
            )
        }
    }

    private func bestPath(for word: String) -> [HostGridPosition]? {
        let candidates = candidatePaths(for: word)
        guard !candidates.isEmpty else { return nil }
        return candidates.max { pathScore($0) < pathScore($1) }
    }

    private func pathScore(_ path: [HostGridPosition]) -> Int {
        path.reduce(0) { partial, position in
            partial + (solvedPositions.contains(position) ? 1 : 0)
        }
    }

    private func candidatePaths(for word: String) -> [[HostGridPosition]] {
        let upperWord = word.uppercased()
        let letters = upperWord.map { String($0) }
        let reversed = Array(letters.reversed())
        let rowCount = grid.count
        let colCount = grid.first?.count ?? 0

        guard !letters.isEmpty else { return [] }
        guard rowCount > 0, colCount > 0 else { return [] }

        var results: [[HostGridPosition]] = []

        for row in 0..<rowCount {
            for col in 0..<colCount {
                for (dr, dc) in directions {
                    var path: [HostGridPosition] = []
                    var collected: [String] = []
                    var isValid = true

                    for step in 0..<letters.count {
                        let r = row + step * dr
                        let c = col + step * dc
                        if r < 0 || c < 0 || r >= rowCount || c >= colCount {
                            isValid = false
                            break
                        }
                        path.append(HostGridPosition(row: r, col: c))
                        collected.append(grid[r][c].uppercased())
                    }

                    guard isValid else { continue }
                    if collected == letters || collected == reversed {
                        results.append(path)
                    }
                }
            }
        }

        return results
    }
}

private struct PuzzleWordsPreview: View {
    let words: [String]
    let foundWords: Set<String>
    let displayMode: HostWordHintMode

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if displayMode == .definition {
                LazyVStack(spacing: 8) {
                    ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                        let displayText = HostWordHints.displayText(for: word, mode: displayMode)
                        WordChip(
                            word: displayText,
                            isFound: foundWords.contains(word.uppercased()),
                            allowMultiline: true,
                            expandsHorizontally: true
                        )
                    }
                }
                .padding(.trailing, 4)
            } else {
                WrappingFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                        let displayText = HostWordHints.displayText(for: word, mode: displayMode)
                        WordChip(
                            word: displayText,
                            isFound: foundWords.contains(word.uppercased()),
                            allowMultiline: false,
                            expandsHorizontally: false
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 4)
            }
        }
    }

    private struct WordChip: View {
        let word: String
        let isFound: Bool
        let allowMultiline: Bool
        let expandsHorizontally: Bool

        private var chipFill: Color {
            isFound ? Color.accentColor.opacity(0.16) : Color(.tertiarySystemBackground)
        }

        private var chipStroke: Color {
            isFound ? Color.accentColor.opacity(0.42) : Color.secondary.opacity(0.30)
        }

        private var labelColor: Color {
            isFound ? Color.accentColor.opacity(0.9) : .primary
        }

        @ViewBuilder
        var body: some View {
            let chipContent = HStack(spacing: 6) {
                Text(word)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(allowMultiline ? nil : 1)
                    .minimumScaleFactor(allowMultiline ? 1 : 0.45)
                    .allowsTightening(true)
                    .fixedSize(horizontal: false, vertical: allowMultiline)
                    .strikethrough(isFound, color: Color.accentColor)
                    .foregroundStyle(labelColor)

                if isFound && !allowMultiline {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .symbolEffect(.bounce, value: isFound)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Capsule().fill(chipFill))
            .overlay(
                Capsule()
                    .stroke(chipStroke, lineWidth: 1)
            )
            .scaleEffect(isFound ? 1.0 : 0.98)
            .animation(.spring(response: 0.35, dampingFraction: 0.74), value: isFound)

            if expandsHorizontally {
                chipContent
                    .frame(maxWidth: .infinity, alignment: allowMultiline ? .leading : .center)
            } else {
                chipContent
            }
        }
    }
}

private struct WrappingFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var x: CGFloat = 0
        var totalHeight: CGFloat = 0
        var lineHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0 && x + size.width > maxWidth {
                usedWidth = max(usedWidth, x - horizontalSpacing)
                totalHeight += lineHeight + verticalSpacing
                x = 0
                lineHeight = 0
            }

            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }

        if !subviews.isEmpty {
            usedWidth = max(usedWidth, max(0, x - horizontalSpacing))
            totalHeight += lineHeight
        }

        let finalWidth = proposal.width ?? usedWidth
        return CGSize(width: finalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > bounds.minX && x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

private struct DifficultySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gridSize: Int
    @State private var appearanceMode: HostAppearanceMode
    @State private var wordHintMode: HostWordHintMode
    @State private var enableCelebrations: Bool
    @State private var enableHaptics: Bool
    @State private var enableSound: Bool
    @State private var celebrationIntensity: HostCelebrationIntensity
    let onSave: (Int, HostAppearanceMode, HostWordHintMode, HostCelebrationPreferences) -> Void

    init(
        currentGridSize: Int,
        currentAppearanceMode: HostAppearanceMode,
        currentWordHintMode: HostWordHintMode,
        onSave: @escaping (Int, HostAppearanceMode, HostWordHintMode, HostCelebrationPreferences) -> Void
    ) {
        let celebrationPreferences = HostCelebrationSettings.preferences()
        _gridSize = State(initialValue: HostDifficultySettings.clampGridSize(currentGridSize))
        _appearanceMode = State(initialValue: currentAppearanceMode)
        _wordHintMode = State(initialValue: currentWordHintMode)
        _enableCelebrations = State(initialValue: celebrationPreferences.enableCelebrations)
        _enableHaptics = State(initialValue: celebrationPreferences.enableHaptics)
        _enableSound = State(initialValue: celebrationPreferences.enableSound)
        _celebrationIntensity = State(initialValue: celebrationPreferences.intensity)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dificultad") {
                    Stepper(value: $gridSize, in: HostDifficultySettings.minGridSize...HostDifficultySettings.maxGridSize) {
                        Text("Tamano de sopa: \(gridSize)x\(gridSize)")
                    }
                    Text("A mayor tamano, mas dificultad. En el widget las letras y el area tactil se reducen para que entre la cuadricula.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apariencia") {
                    Picker("Tema", selection: $appearanceMode) {
                        ForEach(HostAppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Pistas") {
                    Picker("Modo", selection: $wordHintMode) {
                        ForEach(HostWordHintMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("En definicion, veras la descripcion sin mostrar la palabra.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Celebraciones") {
                    Toggle("Animaciones de celebracion", isOn: $enableCelebrations)
                    Toggle("Haptics", isOn: $enableHaptics)
                    Toggle("Sonido", isOn: $enableSound)
                    Picker("Intensidad", selection: $celebrationIntensity) {
                        ForEach(HostCelebrationIntensity.allCases) { intensity in
                            Text(intensity.title).tag(intensity)
                        }
                    }
                    Text("Si Reduce Motion esta activo, se desactivan las particulas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        let preferences = HostCelebrationPreferences(
                            enableCelebrations: enableCelebrations,
                            enableHaptics: enableHaptics,
                            enableSound: enableSound,
                            intensity: celebrationIntensity
                        )
                        onSave(gridSize, appearanceMode, wordHintMode, preferences)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HostPuzzle {
    let number: Int
    let grid: [[String]]
    let words: [String]
}

private struct HostGridPosition: Hashable {
    let row: Int
    let col: Int
}

private struct HostPuzzleProgress {
    let foundWords: Set<String>
    let solvedPositions: Set<HostGridPosition>

    static let empty = HostPuzzleProgress(foundWords: [], solvedPositions: [])
}

private struct HostSharedPosition: Codable, Hashable {
    let r: Int
    let c: Int
}

private enum HostSharedFeedbackKind: String, Codable {
    case correct
    case incorrect
}

private struct HostSharedFeedback: Codable, Equatable {
    var kind: HostSharedFeedbackKind
    var positions: [HostSharedPosition]
    var expiresAt: Date
}

private struct HostSharedPuzzleState: Codable, Equatable {
    var grid: [[String]]
    var words: [String]
    var gridSize: Int
    var anchor: HostSharedPosition?
    var foundWords: Set<String>
    var solvedPositions: Set<HostSharedPosition>
    var puzzleIndex: Int
    var isHelpVisible: Bool
    var feedback: HostSharedFeedback?
    var pendingWord: String?
    var pendingSolvedPositions: Set<HostSharedPosition>
    var nextHintWord: String?
    var nextHintExpiresAt: Date?

    private enum CodingKeys: String, CodingKey {
        case grid
        case words
        case gridSize
        case anchor
        case foundWords
        case solvedPositions
        case puzzleIndex
        case isHelpVisible
        case feedback
        case pendingWord
        case pendingSolvedPositions
        case nextHintWord
        case nextHintExpiresAt
    }

    var isCompleted: Bool {
        let expected = Set(words.map { $0.uppercased() })
        return !expected.isEmpty && expected.isSubset(of: Set(foundWords.map { $0.uppercased() }))
    }

    func progress(for puzzle: HostPuzzle) -> HostPuzzleProgress {
        let puzzleWords = Set(puzzle.words.map { $0.uppercased() })
        let normalizedFound = Set(foundWords.map { $0.uppercased() }).intersection(puzzleWords)
        let maxRow = puzzle.grid.count
        let maxCol = puzzle.grid.first?.count ?? 0
        let normalizedPositions = solvedPositions.compactMap { position -> HostGridPosition? in
            guard position.r >= 0, position.c >= 0, position.r < maxRow, position.c < maxCol else {
                return nil
            }
            return HostGridPosition(row: position.r, col: position.c)
        }
        return HostPuzzleProgress(
            foundWords: normalizedFound,
            solvedPositions: Set(normalizedPositions)
        )
    }

    func asAppRecord(dayOffset: Int, gridSize: Int) -> HostAppProgressRecord {
        let positions = solvedPositions.map { HostAppProgressPosition(row: $0.r, col: $0.c) }
        return HostAppProgressRecord(
            dayOffset: dayOffset,
            gridSize: gridSize,
            foundWords: Array(foundWords),
            solvedPositions: positions,
            startedAt: nil,
            endedAt: nil
        )
    }
}

private struct HostAppProgressPosition: Codable, Hashable {
    let row: Int
    let col: Int
}

private struct HostAppProgressRecord: Codable {
    let dayOffset: Int
    let gridSize: Int
    let foundWords: [String]
    let solvedPositions: [HostAppProgressPosition]
    let startedAt: TimeInterval?
    let endedAt: TimeInterval?

    var startedDate: Date? {
        startedAt.map { Date(timeIntervalSince1970: $0) }
    }

    var endedDate: Date? {
        endedAt.map { Date(timeIntervalSince1970: $0) }
    }

    func progress(for puzzle: HostPuzzle) -> HostPuzzleProgress {
        let puzzleWords = Set(puzzle.words.map { $0.uppercased() })
        let normalizedFound = Set(foundWords.map { $0.uppercased() }).intersection(puzzleWords)
        let maxRow = puzzle.grid.count
        let maxCol = puzzle.grid.first?.count ?? 0
        let normalizedPositions = solvedPositions.compactMap { position -> HostGridPosition? in
            guard position.row >= 0, position.col >= 0, position.row < maxRow, position.col < maxCol else {
                return nil
            }
            return HostGridPosition(row: position.row, col: position.col)
        }
        return HostPuzzleProgress(
            foundWords: normalizedFound,
            solvedPositions: Set(normalizedPositions)
        )
    }
}

private enum HostSharedPuzzleStateStore {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let stateKey = "puzzle_state_v3"
    private static let rotationBoundaryKey = "puzzle_rotation_boundary_v3"
    private static let resetRequestKey = "puzzle_reset_request_v1"
    private static let lastAppliedResetKey = "puzzle_last_applied_reset_v1"
    private static let widgetKind = "WordSearchWidget"

    static func loadState(now: Date, preferredGridSize: Int) -> HostSharedPuzzleState {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return makeState(puzzleIndex: 0, gridSize: preferredGridSize)
        }

        let clampedSize = HostDifficultySettings.clampGridSize(preferredGridSize)
        let decoded = decodeState(defaults: defaults)
        var state = decoded ?? makeState(puzzleIndex: 0, gridSize: clampedSize)
        let original = state

        state = normalizedState(state, preferredGridSize: clampedSize)
        state = applyExternalResetIfNeeded(state: state, defaults: defaults, preferredGridSize: clampedSize)
        state = applyDailyRotationIfNeeded(state: state, defaults: defaults, now: now, preferredGridSize: clampedSize)

        if decoded == nil || state != original {
            save(state, defaults: defaults)
        }

        return state
    }

    static func updateProgress(
        puzzleIndex: Int,
        gridSize: Int,
        foundWords: Set<String>,
        solvedPositions: Set<HostGridPosition>
    ) {
        let now = Date()
        var state = loadState(now: now, preferredGridSize: gridSize)
        guard state.puzzleIndex == puzzleIndex else { return }

        let puzzleWords = Set(state.words.map { $0.uppercased() })
        let normalizedFound = Set(foundWords.map { $0.uppercased() }).intersection(puzzleWords)
        let maxRow = state.grid.count
        let maxCol = state.grid.first?.count ?? 0
        let normalizedPositions = solvedPositions.compactMap { position -> HostSharedPosition? in
            guard position.row >= 0, position.col >= 0, position.row < maxRow, position.col < maxCol else {
                return nil
            }
            return HostSharedPosition(r: position.row, c: position.col)
        }

        state.foundWords = normalizedFound
        state.solvedPositions = Set(normalizedPositions)
        save(state)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func clearProgress(puzzleIndex: Int, gridSize: Int) {
        let now = Date()
        let state = loadState(now: now, preferredGridSize: gridSize)
        guard state.puzzleIndex == puzzleIndex else { return }
        let cleared = clearedState(from: state, preferredGridSize: gridSize)
        save(cleared)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func currentRotationBoundary(for now: Date) -> Date {
        let calendar = Calendar.current
        let todayNine = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        if now >= todayNine {
            return todayNine
        }
        return calendar.date(byAdding: .day, value: -1, to: todayNine) ?? todayNine
    }

    private static func save(_ state: HostSharedPuzzleState) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        save(state, defaults: defaults)
    }

    private static func save(_ state: HostSharedPuzzleState, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey)
    }

    private static func decodeState(defaults: UserDefaults) -> HostSharedPuzzleState? {
        guard let data = defaults.data(forKey: stateKey) else { return nil }
        return try? JSONDecoder().decode(HostSharedPuzzleState.self, from: data)
    }

    private static func makeState(puzzleIndex: Int, gridSize: Int) -> HostSharedPuzzleState {
        let normalized = HostPuzzleCalendar.normalizedPuzzleIndex(puzzleIndex)
        let size = HostDifficultySettings.clampGridSize(gridSize)
        let puzzle = HostPuzzleCalendar.puzzle(forDayOffset: normalized, gridSize: size)
        return HostSharedPuzzleState(
            grid: puzzle.grid,
            words: puzzle.words,
            gridSize: size,
            anchor: nil,
            foundWords: [],
            solvedPositions: [],
            puzzleIndex: normalized,
            isHelpVisible: false,
            feedback: nil,
            pendingWord: nil,
            pendingSolvedPositions: [],
            nextHintWord: nil,
            nextHintExpiresAt: nil
        )
    }

    private static func normalizedState(_ state: HostSharedPuzzleState, preferredGridSize: Int) -> HostSharedPuzzleState {
        let targetSize = HostDifficultySettings.clampGridSize(preferredGridSize)
        guard state.gridSize == targetSize else {
            return makeState(puzzleIndex: state.puzzleIndex, gridSize: targetSize)
        }
        guard state.grid.count == targetSize, state.grid.allSatisfy({ $0.count == targetSize }) else {
            return makeState(puzzleIndex: state.puzzleIndex, gridSize: targetSize)
        }
        return state
    }

    private static func applyExternalResetIfNeeded(
        state: HostSharedPuzzleState,
        defaults: UserDefaults,
        preferredGridSize: Int
    ) -> HostSharedPuzzleState {
        let requestToken = defaults.double(forKey: resetRequestKey)
        let appliedToken = defaults.double(forKey: lastAppliedResetKey)
        guard requestToken > appliedToken else {
            return state
        }

        defaults.set(requestToken, forKey: lastAppliedResetKey)
        return clearedState(from: state, preferredGridSize: preferredGridSize)
    }

    private static func clearedState(from state: HostSharedPuzzleState, preferredGridSize: Int) -> HostSharedPuzzleState {
        let size = HostDifficultySettings.clampGridSize(preferredGridSize)
        let puzzle = HostPuzzleCalendar.puzzle(forDayOffset: state.puzzleIndex, gridSize: size)
        return HostSharedPuzzleState(
            grid: puzzle.grid,
            words: puzzle.words,
            gridSize: size,
            anchor: nil,
            foundWords: [],
            solvedPositions: [],
            puzzleIndex: state.puzzleIndex,
            isHelpVisible: false,
            feedback: nil,
            pendingWord: nil,
            pendingSolvedPositions: [],
            nextHintWord: nil,
            nextHintExpiresAt: nil
        )
    }

    private static func applyDailyRotationIfNeeded(
        state: HostSharedPuzzleState,
        defaults: UserDefaults,
        now: Date,
        preferredGridSize: Int
    ) -> HostSharedPuzzleState {
        let boundary = currentRotationBoundary(for: now)
        let boundaryTimestamp = boundary.timeIntervalSince1970

        guard let existing = defaults.object(forKey: rotationBoundaryKey) as? Double else {
            defaults.set(boundaryTimestamp, forKey: rotationBoundaryKey)
            return state
        }

        if existing >= boundaryTimestamp {
            return state
        }

        let previousBoundary = Date(timeIntervalSince1970: existing)
        let steps = max(rotationSteps(from: previousBoundary, to: boundary), 1)
        let nextIndex = HostPuzzleCalendar.normalizedPuzzleIndex(state.puzzleIndex + steps)
        defaults.set(boundaryTimestamp, forKey: rotationBoundaryKey)
        return makeState(puzzleIndex: nextIndex, gridSize: preferredGridSize)
    }

    private static func rotationSteps(from previousBoundary: Date, to currentBoundary: Date) -> Int {
        let calendar = Calendar.current
        var steps = 0
        var marker = previousBoundary

        while marker < currentBoundary {
            guard let next = calendar.date(byAdding: .day, value: 1, to: marker) else { break }
            marker = next
            steps += 1
            if steps > 3660 {
                break
            }
        }

        return steps
    }
}

private enum HostAppProgressStore {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let stateKey = "puzzle_app_progress_v1"

    static func key(for dayOffset: Int, gridSize: Int) -> String {
        "\(dayOffset)-\(gridSize)"
    }

    static func loadRecords() -> [String: HostAppProgressRecord] {
        guard let defaults = UserDefaults(suiteName: suite) else { return [:] }
        guard let data = defaults.data(forKey: stateKey) else { return [:] }
        guard let decoded = try? JSONDecoder().decode([String: HostAppProgressRecord].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func save(_ record: HostAppProgressRecord) {
        var records = loadRecords()
        records[key(for: record.dayOffset, gridSize: record.gridSize)] = record
        saveRecords(records)
    }

    static func reset(dayOffset: Int, gridSize: Int) {
        var records = loadRecords()
        records.removeValue(forKey: key(for: dayOffset, gridSize: gridSize))
        saveRecords(records)
    }

    private static func saveRecords(_ records: [String: HostAppProgressRecord]) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: stateKey)
    }
}

private enum HostCompletionStore {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let key = "puzzle_completed_offsets_v1"

    static func load() -> Set<Int> {
        guard let defaults = UserDefaults(suiteName: suite) else { return [] }
        let stored = defaults.array(forKey: key) as? [Int] ?? []
        return Set(stored)
    }

    static func markCompleted(dayOffset: Int) {
        var current = load()
        current.insert(dayOffset)
        save(current)
    }

    private static func save(_ offsets: Set<Int>) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(Array(offsets).sorted(), forKey: key)
    }
}

private struct HostStreakState {
    var current: Int
    var lastCompletedOffset: Int
}

private enum HostStreakStore {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let currentKey = "puzzle_streak_current_v1"
    private static let lastCompletedKey = "puzzle_streak_last_completed_v1"

    static func load() -> HostStreakState {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return HostStreakState(current: 0, lastCompletedOffset: -1)
        }
        let current = defaults.integer(forKey: currentKey)
        let last = defaults.object(forKey: lastCompletedKey) as? Int ?? -1
        return HostStreakState(current: current, lastCompletedOffset: last)
    }

    static func refresh(todayOffset: Int) -> HostStreakState {
        var state = load()
        if state.lastCompletedOffset >= 0 && state.lastCompletedOffset < todayOffset - 1 {
            state.current = 0
            save(state)
        }
        return state
    }

    static func markCompleted(dayOffset: Int, todayOffset: Int) -> HostStreakState {
        var state = load()
        guard dayOffset == todayOffset else { return state }
        guard state.lastCompletedOffset != todayOffset else { return state }

        if state.lastCompletedOffset == todayOffset - 1 {
            state.current += 1
        } else {
            state.current = 1
        }
        state.lastCompletedOffset = todayOffset
        save(state)
        return state
    }

    private static func save(_ state: HostStreakState) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(state.current, forKey: currentKey)
        defaults.set(state.lastCompletedOffset, forKey: lastCompletedKey)
    }
}

private struct HostHintState: Equatable {
    var available: Int
    var lastRechargeOffset: Int
    var lastRewardOffset: Int

    static let empty = HostHintState(available: 0, lastRechargeOffset: -1, lastRewardOffset: -1)
}

private enum HostHintStore {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let availableKey = "puzzle_hint_available_v1"
    private static let rechargeKey = "puzzle_hint_recharge_v1"
    private static let rewardKey = "puzzle_hint_reward_v1"
    private static let initialHints = 3
    private static let dailyRecharge = 1
    private static let completionReward = 1
    static let maxHints = 10

    static func state(todayOffset: Int) -> HostHintState {
        var state = load()

        if state.lastRechargeOffset == -1 {
            state.available = min(maxHints, max(state.available, initialHints))
            state.lastRechargeOffset = todayOffset
        }

        if todayOffset > state.lastRechargeOffset {
            let delta = todayOffset - state.lastRechargeOffset
            state.available = min(maxHints, state.available + delta * dailyRecharge)
            state.lastRechargeOffset = todayOffset
        }

        save(state)
        return state
    }

    static func spendHint(todayOffset: Int) -> Bool {
        var state = state(todayOffset: todayOffset)
        guard state.available > 0 else { return false }
        state.available -= 1
        save(state)
        return true
    }

    static func rewardCompletion(dayOffset: Int, todayOffset: Int) -> Bool {
        guard dayOffset == todayOffset else { return false }
        var state = state(todayOffset: todayOffset)
        guard state.lastRewardOffset != todayOffset else { return false }
        state.available = min(maxHints, state.available + completionReward)
        state.lastRewardOffset = todayOffset
        save(state)
        return true
    }

    static func wasRewarded(todayOffset: Int) -> Bool {
        let state = load()
        return state.lastRewardOffset == todayOffset
    }

    private static func load() -> HostHintState {
        guard let defaults = UserDefaults(suiteName: suite) else { return .empty }
        let available = max(0, defaults.object(forKey: availableKey) as? Int ?? 0)
        let recharge = defaults.object(forKey: rechargeKey) as? Int ?? -1
        let reward = defaults.object(forKey: rewardKey) as? Int ?? -1
        return HostHintState(available: available, lastRechargeOffset: recharge, lastRewardOffset: reward)
    }

    private static func save(_ state: HostHintState) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        let clamped = min(maxHints, max(0, state.available))
        defaults.set(clamped, forKey: availableKey)
        defaults.set(state.lastRechargeOffset, forKey: rechargeKey)
        defaults.set(state.lastRewardOffset, forKey: rewardKey)
    }
}

private enum HostDurationFormatter {
    static func elapsedTime(from start: Date?, to end: Date?) -> String? {
        guard let start, let end else { return nil }
        let interval = max(0, end.timeIntervalSince(start))
        return formatted(interval: interval)
    }

    private static func formatted(interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private enum HostWordPathFinder {
    private static let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]

    static func bestPath(for word: String, in grid: [[String]]) -> [HostGridPosition]? {
        let candidates = candidatePaths(for: word, in: grid)
        guard !candidates.isEmpty else { return nil }
        return candidates.randomElement()
    }

    static func candidatePaths(for word: String, in grid: [[String]]) -> [[HostGridPosition]] {
        let upperWord = word.uppercased()
        let letters = upperWord.map { String($0) }
        let reversed = Array(letters.reversed())
        let rowCount = grid.count
        let colCount = grid.first?.count ?? 0

        guard !letters.isEmpty else { return [] }
        guard rowCount > 0, colCount > 0 else { return [] }

        var results: [[HostGridPosition]] = []

        for row in 0..<rowCount {
            for col in 0..<colCount {
                for (dr, dc) in directions {
                    var path: [HostGridPosition] = []
                    var collected: [String] = []
                    var isValid = true

                    for step in 0..<letters.count {
                        let r = row + step * dr
                        let c = col + step * dc
                        if r < 0 || c < 0 || r >= rowCount || c >= colCount {
                            isValid = false
                            break
                        }
                        path.append(HostGridPosition(row: r, col: c))
                        collected.append(grid[r][c].uppercased())
                    }

                    guard isValid else { continue }
                    if collected == letters || collected == reversed {
                        results.append(path)
                    }
                }
            }
        }

        return results
    }

    static func anchorUnit(for positions: [HostGridPosition], in grid: [[String]]) -> CGPoint {
        let rows = grid.count
        let cols = grid.first?.count ?? 0
        guard !positions.isEmpty, rows > 0, cols > 0 else {
            return CGPoint(x: 0.5, y: 0.5)
        }

        let avgRow = positions.reduce(0.0) { $0 + Double($1.row) } / Double(positions.count)
        let avgCol = positions.reduce(0.0) { $0 + Double($1.col) } / Double(positions.count)
        let unitX = (avgCol + 0.5) / Double(cols)
        let unitY = (avgRow + 0.5) / Double(rows)
        return CGPoint(
            x: min(max(unitX, 0.0), 1.0),
            y: min(max(unitY, 0.0), 1.0)
        )
    }
}

private enum HostCelebrationIntensity: String, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            return "Baja"
        case .medium:
            return "Media"
        case .high:
            return "Alta"
        }
    }

    var particleBirthRate: Float {
        switch self {
        case .low:
            return 160
        case .medium:
            return 220
        case .high:
            return 300
        }
    }

    var particleVelocity: CGFloat {
        switch self {
        case .low:
            return 90
        case .medium:
            return 110
        case .high:
            return 130
        }
    }

    var particleScale: CGFloat {
        switch self {
        case .low:
            return 0.45
        case .medium:
            return 0.55
        case .high:
            return 0.65
        }
    }
}

private struct HostCelebrationPreferences: Equatable {
    let enableCelebrations: Bool
    let enableHaptics: Bool
    let enableSound: Bool
    let intensity: HostCelebrationIntensity
}

private struct HostCelebrationConfig {
    let popDuration: TimeInterval
    let particleDuration: TimeInterval
    let completionDuration: TimeInterval
    let maxConcurrentCelebrations: Int

    static let `default` = HostCelebrationConfig(
        popDuration: 0.24,
        particleDuration: 0.65,
        completionDuration: 1.4,
        maxConcurrentCelebrations: 2
    )
}

private enum HostCelebrationSettings {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let enableCelebrationsKey = "puzzle_celebrations_enabled_v1"
    private static let enableHapticsKey = "puzzle_celebrations_haptics_v1"
    private static let enableSoundKey = "puzzle_celebrations_sound_v1"
    private static let intensityKey = "puzzle_celebrations_intensity_v1"

    static func preferences() -> HostCelebrationPreferences {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return HostCelebrationPreferences(
                enableCelebrations: true,
                enableHaptics: true,
                enableSound: false,
                intensity: .medium
            )
        }

        let enableCelebrations = defaults.object(forKey: enableCelebrationsKey) as? Bool ?? true
        let enableHaptics = defaults.object(forKey: enableHapticsKey) as? Bool ?? true
        let enableSound = defaults.object(forKey: enableSoundKey) as? Bool ?? false
        let intensityRaw = defaults.string(forKey: intensityKey) ?? HostCelebrationIntensity.medium.rawValue
        let intensity = HostCelebrationIntensity(rawValue: intensityRaw) ?? .medium

        return HostCelebrationPreferences(
            enableCelebrations: enableCelebrations,
            enableHaptics: enableHaptics,
            enableSound: enableSound,
            intensity: intensity
        )
    }

    static func apply(preferences: HostCelebrationPreferences) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(preferences.enableCelebrations, forKey: enableCelebrationsKey)
        defaults.set(preferences.enableHaptics, forKey: enableHapticsKey)
        defaults.set(preferences.enableSound, forKey: enableSoundKey)
        defaults.set(preferences.intensity.rawValue, forKey: intensityKey)
    }
}

private struct HostWordCelebration: Identifiable {
    let id: UUID
    let wordId: String
    let positions: [HostGridPosition]
    let anchorUnit: CGPoint
    let intensity: HostCelebrationIntensity
    let showsParticles: Bool
    let popDuration: TimeInterval
    let particleDuration: TimeInterval
    let reduceMotion: Bool
}

private struct HostCompletionStats {
    let elapsedTime: String?
}

private struct HostCompletionCelebration: Identifiable {
    let id: UUID
    let stats: HostCompletionStats
    let duration: TimeInterval
    let reduceMotion: Bool
    let showsConfetti: Bool
}

@MainActor
private final class HostCelebrationController: ObservableObject {
    @Published private(set) var wordCelebrations: [HostWordCelebration] = []
    @Published private(set) var completionCelebration: HostCompletionCelebration?

    private let config = HostCelebrationConfig.default

    func celebrateWord(
        wordId: String,
        pathCells: [HostGridPosition],
        anchorPoint: CGPoint,
        intensity: HostCelebrationIntensity,
        preferences: HostCelebrationPreferences,
        reduceMotion: Bool
    ) {
        if preferences.enableHaptics {
            HostHaptics.wordSuccess()
        }
        if preferences.enableSound {
            HostSoundPlayer.play(.word)
        }

        guard preferences.enableCelebrations else { return }
        guard !pathCells.isEmpty else { return }

        let particleCount = wordCelebrations.filter { $0.showsParticles }.count
        let showParticles = !reduceMotion && particleCount < config.maxConcurrentCelebrations

        let celebration = HostWordCelebration(
            id: UUID(),
            wordId: wordId,
            positions: pathCells,
            anchorUnit: CGPoint(
                x: min(max(anchorPoint.x, 0.0), 1.0),
                y: min(max(anchorPoint.y, 0.0), 1.0)
            ),
            intensity: intensity,
            showsParticles: showParticles,
            popDuration: config.popDuration,
            particleDuration: config.particleDuration,
            reduceMotion: reduceMotion
        )

        wordCelebrations.append(celebration)

        let removalDelay = max(config.popDuration, config.particleDuration) + 0.08
        Task {
            try? await Task.sleep(nanoseconds: UInt64(removalDelay * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.18)) {
                    wordCelebrations.removeAll { $0.id == celebration.id }
                }
            }
        }
    }

    func celebrateCompletion(
        stats: HostCompletionStats,
        preferences: HostCelebrationPreferences,
        reduceMotion: Bool
    ) {
        if preferences.enableHaptics {
            HostHaptics.completionSuccess()
        }
        if preferences.enableSound {
            HostSoundPlayer.play(.completion)
        }

        guard preferences.enableCelebrations else { return }

        let celebration = HostCompletionCelebration(
            id: UUID(),
            stats: stats,
            duration: config.completionDuration,
            reduceMotion: reduceMotion,
            showsConfetti: !reduceMotion
        )

        completionCelebration = celebration

        Task {
            try? await Task.sleep(nanoseconds: UInt64(config.completionDuration * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    completionCelebration = nil
                }
            }
        }
    }
}

private enum HostHaptics {
    static func wordSuccess() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func completionSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

private enum HostSoundEffect {
    case word
    case completion

    var soundID: SystemSoundID {
        switch self {
        case .word:
            return 1104
        case .completion:
            return 1105
        }
    }
}

private enum HostSoundPlayer {
    static func play(_ effect: HostSoundEffect) {
        AudioServicesPlaySystemSound(effect.soundID)
    }
}

private enum HostDateFormatter {
    private static let weekdays = [
        "domingo", "lunes", "martes", "miercoles", "jueves", "viernes", "sabado"
    ]
    private static let shortWeekdays = [
        "dom", "lun", "mar", "mie", "jue", "vie", "sab"
    ]
    private static let months = [
        "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    ]
    private static let shortMonths = [
        "Ene", "Feb", "Mar", "Abr", "May", "Jun",
        "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"
    ]

    static func weekdayName(for date: Date) -> String {
        let index = max(0, min(weekdays.count - 1, Calendar.current.component(.weekday, from: date) - 1))
        return weekdays[index]
    }

    static func shortWeekday(for date: Date) -> String {
        let index = max(0, min(shortWeekdays.count - 1, Calendar.current.component(.weekday, from: date) - 1))
        return shortWeekdays[index]
    }

    static func monthDay(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let monthIndex = max(0, min(months.count - 1, Calendar.current.component(.month, from: date) - 1))
        return "\(day) de \(months[monthIndex])"
    }

    static func monthDayCompact(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let monthIndex = max(0, min(shortMonths.count - 1, Calendar.current.component(.month, from: date) - 1))
        return "\(day) \(shortMonths[monthIndex])"
    }
}

private enum HostTimeFormatter {
    static func clock(from interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct HostGeneratedPuzzle {
    let grid: [[String]]
    let words: [String]
}

private struct HostWidgetProgressSnapshot {
    let grid: [[String]]
    let words: [String]
    let foundWords: Set<String>
    let solvedPositions: Set<HostGridPosition>
}

private enum HostWidgetProgressStore {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let stateKey = "puzzle_state_v3"

    static func loadSnapshot() -> HostWidgetProgressSnapshot? {
        guard let defaults = UserDefaults(suiteName: suite) else { return nil }
        guard let data = defaults.data(forKey: stateKey) else { return nil }
        guard let decoded = try? JSONDecoder().decode(SharedWidgetState.self, from: data) else { return nil }

        let normalizedGrid = decoded.grid.map { row in row.map { $0.uppercased() } }
        let normalizedWords = decoded.words.map { $0.uppercased() }
        let normalizedFoundWords = Set(decoded.foundWords.map { $0.uppercased() })
        let solvedPositions = Set(decoded.solvedPositions.map { HostGridPosition(row: $0.r, col: $0.c) })

        return HostWidgetProgressSnapshot(
            grid: normalizedGrid,
            words: normalizedWords,
            foundWords: normalizedFoundWords,
            solvedPositions: solvedPositions
        )
    }

    private struct SharedWidgetState: Decodable {
        let grid: [[String]]
        let words: [String]
        let foundWords: Set<String>
        let solvedPositions: Set<SharedWidgetPosition>

        private enum CodingKeys: String, CodingKey {
            case grid
            case words
            case foundWords
            case solvedPositions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            grid = try container.decodeIfPresent([[String]].self, forKey: .grid) ?? []
            words = try container.decodeIfPresent([String].self, forKey: .words) ?? []
            foundWords = try container.decodeIfPresent(Set<String>.self, forKey: .foundWords) ?? []
            solvedPositions = try container.decodeIfPresent(Set<SharedWidgetPosition>.self, forKey: .solvedPositions) ?? []
        }
    }

    private struct SharedWidgetPosition: Hashable, Decodable {
        let r: Int
        let c: Int
    }
}

private enum HostDifficultySettings {
    static let suite = "group.com.pedrocarrasco.miapp"
    static let gridSizeKey = "puzzle_grid_size_v1"
    static let minGridSize = 7
    static let maxGridSize = 12

    static func clampGridSize(_ value: Int) -> Int {
        min(max(value, minGridSize), maxGridSize)
    }

    static func gridSize() -> Int {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return minGridSize
        }
        let stored = defaults.integer(forKey: gridSizeKey)
        if stored == 0 {
            defaults.set(minGridSize, forKey: gridSizeKey)
            return minGridSize
        }
        let clamped = clampGridSize(stored)
        if clamped != stored {
            defaults.set(clamped, forKey: gridSizeKey)
        }
        return clamped
    }

    static func setGridSize(_ value: Int) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(clampGridSize(value), forKey: gridSizeKey)
    }
}

private enum HostAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

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

private enum HostAppearanceSettings {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let appearanceModeKey = "puzzle_theme_mode_v1"

    static func mode() -> HostAppearanceMode {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return .system
        }
        guard let raw = defaults.string(forKey: appearanceModeKey) else {
            return .system
        }
        return HostAppearanceMode(rawValue: raw) ?? .system
    }

    static func setMode(_ mode: HostAppearanceMode) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(mode.rawValue, forKey: appearanceModeKey)
    }
}

private enum HostWordHintMode: String, CaseIterable, Identifiable {
    case word
    case definition

    var id: String { rawValue }

    var title: String {
        switch self {
        case .word:
            return "Palabra"
        case .definition:
            return "Definicion"
        }
    }
}

private enum HostWordHintSettings {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let wordHintModeKey = "puzzle_word_hint_mode_v1"

    static func mode() -> HostWordHintMode {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return .word
        }
        guard let raw = defaults.string(forKey: wordHintModeKey) else {
            return .word
        }
        return HostWordHintMode(rawValue: raw) ?? .word
    }

    static func setMode(_ mode: HostWordHintMode) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(mode.rawValue, forKey: wordHintModeKey)
    }
}

private enum HostWordHints {
    static func displayText(for word: String, mode: HostWordHintMode) -> String {
        switch mode {
        case .word:
            return word
        case .definition:
            return definition(for: word) ?? "Sin definicion"
        }
    }

    static func definition(for word: String) -> String? {
        let normalized = word.uppercased()
        return definitions[normalized]
    }

    private static let definitions: [String: String] = [
        "ARBOL": "Planta grande con tronco y ramas.",
        "TIERRA": "Suelo donde crecen las plantas.",
        "NUBE": "Masa de vapor de agua en el cielo.",
        "MAR": "Gran extension de agua salada.",
        "SOL": "Estrella que ilumina la Tierra.",
        "RIO": "Corriente natural de agua.",
        "FLOR": "Parte de la planta que produce semillas.",
        "LUNA": "Satelite natural de la Tierra.",
        "MONTE": "Elevacion natural del terreno.",
        "VALLE": "Zona baja entre montes.",
        "BOSQUE": "Conjunto denso de arboles.",
        "RAMA": "Parte del arbol que sale del tronco.",
        "ROCA": "Piedra grande y dura.",
        "PLAYA": "Orilla de arena junto al mar.",
        "NIEVE": "Agua congelada que cae del cielo.",
        "VIENTO": "Movimiento del aire.",
        "TRUENO": "Sonido fuerte tras un rayo.",
        "FUEGO": "Combustion que produce calor y luz.",
        "ARENA": "Granitos que forman playas o desiertos.",
        "ISLA": "Tierra rodeada de agua.",
        "CIELO": "Espacio visible sobre la Tierra.",
        "SELVA": "Bosque tropical muy denso.",
        "LLUVIA": "Agua que cae de las nubes.",
        "CAMINO": "Via o senda para ir de un lugar a otro.",
        "MUSGO": "Planta pequena que crece en lugares humedos.",
        "LAGO": "Cuerpo de agua interior.",
        "PRIMAVERA": "Estacion del anio entre invierno y verano.",
        "HORIZONTE": "Linea donde parece unirse cielo y tierra.",
        "ESTRELLA": "Cuerpo celeste que emite luz.",
        "PLANETA": "Cuerpo que orbita una estrella.",
        "QUESO": "Lacteo curado o fresco hecho de leche.",
        "PAN": "Alimento horneado a base de harina.",
        "MIEL": "Sustancia dulce producida por abejas.",
        "LECHE": "Liquido blanco nutritivo de mamiferos.",
        "UVA": "Fruto pequeno que crece en racimos.",
        "PERA": "Fruta dulce de forma alargada.",
        "CAFE": "Bebida hecha con granos tostados.",
        "TOMATE": "Fruto rojo usado en ensaladas y salsas.",
        "ACEITE": "Liquido graso usado para cocinar.",
        "SAL": "Condimento mineral que realza el sabor.",
        "PASTA": "Masa alimenticia de harina y agua.",
        "ARROZ": "Cereal en grano muy usado en comidas.",
        "PAPAYA": "Fruta tropical de pulpa naranja.",
        "MANGO": "Fruta tropical dulce y jugosa.",
        "BANANA": "Fruta alargada y amarilla.",
        "NARANJA": "Fruta citrica redonda y dulce.",
        "CEREZA": "Fruta pequena roja con hueso.",
        "SOPA": "Comida liquida y caliente.",
        "TORTILLA": "Preparacion de huevo o de masa de maiz.",
        "GALLETA": "Dulce horneado y crujiente.",
        "CHOCOLATE": "Dulce hecho con cacao.",
        "YOGUR": "Lacteo fermentado y cremoso.",
        "MANZANA": "Fruta redonda y crujiente.",
        "AVENA": "Cereal usado en desayunos.",
        "ENSALADA": "Mezcla de vegetales frescos.",
        "PIMIENTO": "Hortaliza de piel lisa y colorida.",
        "LIMON": "Fruta citrica muy acida.",
        "COCO": "Fruto tropical con cascara dura.",
        "ALMENDRA": "Semilla comestible con cascara dura.",
        "ALBAHACA": "Hierba aromatica usada en cocina.",
        "TREN": "Vehiculo que va sobre vias.",
        "BUS": "Vehiculo grande para pasajeros.",
        "CARRO": "Vehiculo de cuatro ruedas.",
        "PUERTA": "Elemento que abre o cierra un paso.",
        "LIBRO": "Conjunto de paginas encuadernadas.",
        "CINE": "Lugar para ver peliculas.",
        "PUENTE": "Estructura que cruza un rio o via.",
        "CALLE": "Via urbana entre edificios.",
        "METRO": "Transporte subterraneo en ciudades.",
        "AVION": "Vehiculo que vuela.",
        "BARRIO": "Zona de una ciudad con identidad propia.",
        "PLAZA": "Espacio publico abierto en la ciudad.",
        "PARQUE": "Area verde para ocio.",
        "TORRE": "Construccion alta y estrecha.",
        "MUSEO": "Lugar donde se exhibe arte o historia.",
        "MAPA": "Representacion grafica de un lugar.",
        "RUTA": "Camino planificado para ir a un destino.",
        "BICICLETA": "Vehiculo de dos ruedas con pedales.",
        "TRAFICO": "Circulacion de vehiculos.",
        "SEMAFORO": "Senal luminosa para regular el paso.",
        "ESTACION": "Lugar de salida y llegada de transporte.",
        "AUTOPISTA": "Via rapida de varios carriles.",
        "TAXI": "Vehiculo de servicio publico individual.",
        "MOTOR": "Maquina que genera movimiento.",
        "VIAJE": "Desplazamiento de un lugar a otro.",
        "MOCHILA": "Bolso que se lleva en la espalda.",
        "PASEO": "Actividad de caminar o recorrer.",
        "CIUDAD": "Asentamiento grande y urbano.",
        "CARTEL": "Placa o anuncio con informacion."
    ]
}

private enum HostPuzzleCalendar {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let installDateKey = "puzzle_installation_date_v1"
    private static let themes: [[String]] = [
        [
            "ARBOL", "TIERRA", "NUBE", "MAR", "SOL", "RIO", "FLOR", "LUNA", "MONTE", "VALLE",
            "BOSQUE", "RAMA", "ROCA", "PLAYA", "NIEVE", "VIENTO", "TRUENO", "FUEGO", "ARENA",
            "ISLA", "CIELO", "SELVA", "LLUVIA", "CAMINO", "MUSGO", "LAGO", "PRIMAVERA",
            "HORIZONTE", "ESTRELLA", "PLANETA"
        ],
        [
            "QUESO", "PAN", "MIEL", "LECHE", "UVA", "PERA", "CAFE", "TOMATE", "ACEITE", "SAL",
            "PASTA", "ARROZ", "PAPAYA", "MANGO", "BANANA", "NARANJA", "CEREZA", "SOPA",
            "TORTILLA", "GALLETA", "CHOCOLATE", "YOGUR", "MANZANA", "AVENA", "ENSALADA",
            "PIMIENTO", "LIMON", "COCO", "ALMENDRA", "ALBAHACA"
        ],
        [
            "TREN", "BUS", "CARRO", "PUERTA", "PLAYA", "LIBRO", "CINE", "PUENTE", "CALLE",
            "METRO", "AVION", "BARRIO", "PLAZA", "PARQUE", "TORRE", "MUSEO", "MAPA", "RUTA",
            "BICICLETA", "TRAFICO", "SEMAFORO", "ESTACION", "AUTOPISTA", "TAXI", "MOTOR",
            "VIAJE", "MOCHILA", "PASEO", "CIUDAD", "CARTEL"
        ]
    ]

    static func installationDate() -> Date {
        let calendar = Calendar.current
        let fallback = calendar.startOfDay(for: Date())
        guard let defaults = UserDefaults(suiteName: suite) else {
            return fallback
        }

        if let stored = defaults.object(forKey: installDateKey) as? Date {
            return calendar.startOfDay(for: stored)
        }

        defaults.set(fallback, forKey: installDateKey)
        return fallback
    }

    static func dayOffset(from start: Date, to target: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let targetDay = calendar.startOfDay(for: target)
        return max(calendar.dateComponents([.day], from: startDay, to: targetDay).day ?? 0, 0)
    }

    static func date(from start: Date, dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        return calendar.date(byAdding: .day, value: dayOffset, to: startDay) ?? startDay
    }

    static func puzzle(forDayOffset offset: Int, gridSize: Int) -> HostPuzzle {
        let normalized = normalizedPuzzleIndex(offset)
        let size = HostDifficultySettings.clampGridSize(gridSize)
        let seed = stableSeed(dayOffset: offset, gridSize: size)
        let words = selectWords(from: themes[normalized], gridSize: size, seed: seed)
        let generated = HostPuzzleGenerator.generate(gridSize: size, words: words, seed: seed)
        return HostPuzzle(number: normalized + 1, grid: generated.grid, words: generated.words)
    }

    static func normalizedPuzzleIndex(_ offset: Int) -> Int {
        let count = max(themes.count, 1)
        let value = offset % count
        return value >= 0 ? value : value + count
    }

    private static func stableSeed(dayOffset: Int, gridSize: Int) -> UInt64 {
        let a = UInt64(bitPattern: Int64(dayOffset))
        let b = UInt64(gridSize) << 32
        return (a &* 0x9E3779B185EBCA87) ^ b ^ 0xC0DEC0FFEE12345F
    }

    private static func selectWords(from pool: [String], gridSize: Int, seed: UInt64) -> [String] {
        var filtered = pool
            .map { $0.uppercased() }
            .filter { $0.count >= 3 && $0.count <= gridSize }
        if filtered.isEmpty {
            filtered = ["SOL", "MAR", "RIO", "LUNA", "FLOR", "ROCA"]
        }

        var rng = HostPuzzleGenerator.SeededGenerator(seed: seed ^ 0xA11CE5EED)
        for index in stride(from: filtered.count - 1, through: 1, by: -1) {
            let swapAt = rng.int(upperBound: index + 1)
            if swapAt != index {
                filtered.swapAt(index, swapAt)
            }
        }

        let targetCount = min(filtered.count, max(7, 7 + (gridSize - 7) * 2))
        return Array(filtered.prefix(targetCount))
    }
}

private enum HostPuzzleGenerator {
    private static let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]
    private static let alphabet: [String] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }

    struct SeededGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0x1234ABCD5678EF90 : seed
        }

        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }

        mutating func int(upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(next() % UInt64(upperBound))
        }
    }

    static func generate(gridSize: Int, words: [String], seed: UInt64) -> HostGeneratedPuzzle {
        let size = HostDifficultySettings.clampGridSize(gridSize)
        let sortedWords = words
            .map { $0.uppercased() }
            .filter { !$0.isEmpty && $0.count <= size }
            .sorted { $0.count > $1.count }

        var fallback = makePuzzle(size: size, words: sortedWords, seed: seed, reduction: 0)
        if fallback.words.count >= 4 {
            return fallback
        }

        for reduction in [2, 4, 6] {
            let reduced = Array(sortedWords.prefix(max(4, sortedWords.count - reduction)))
            let attempt = makePuzzle(size: size, words: reduced, seed: seed, reduction: reduction)
            if attempt.words.count > fallback.words.count {
                fallback = attempt
            }
            if attempt.words.count >= max(4, reduced.count - 1) {
                return attempt
            }
        }

        return fallback
    }

    private static func makePuzzle(size: Int, words: [String], seed: UInt64, reduction: Int) -> HostGeneratedPuzzle {
        var rng = SeededGenerator(seed: seed ^ UInt64(reduction) ^ 0xFEEDBEEF15)
        var board = Array(repeating: Array(repeating: "", count: size), count: size)
        var placedWords: [String] = []

        for word in words {
            if place(word: word, on: &board, size: size, rng: &rng) {
                placedWords.append(word)
            }
        }

        for row in 0..<size {
            for col in 0..<size where board[row][col].isEmpty {
                board[row][col] = alphabet[rng.int(upperBound: alphabet.count)]
            }
        }

        return HostGeneratedPuzzle(grid: board, words: placedWords)
    }

    private static func place(word: String, on board: inout [[String]], size: Int, rng: inout SeededGenerator) -> Bool {
        let letters = word.map { String($0) }
        let count = letters.count
        guard count > 1 else { return false }

        for _ in 0..<300 {
            let direction = directions[rng.int(upperBound: directions.count)]
            let dr = direction.0
            let dc = direction.1

            let minRow = dr < 0 ? count - 1 : 0
            let maxRow = dr > 0 ? size - count : size - 1
            let minCol = dc < 0 ? count - 1 : 0
            let maxCol = dc > 0 ? size - count : size - 1

            if maxRow < minRow || maxCol < minCol {
                continue
            }

            let startRow = minRow + rng.int(upperBound: maxRow - minRow + 1)
            let startCol = minCol + rng.int(upperBound: maxCol - minCol + 1)

            var canPlace = true
            for index in 0..<count {
                let r = startRow + index * dr
                let c = startCol + index * dc
                let existing = board[r][c]
                if !existing.isEmpty && existing != letters[index] {
                    canPlace = false
                    break
                }
            }

            if !canPlace {
                continue
            }

            for index in 0..<count {
                let r = startRow + index * dr
                let c = startCol + index * dc
                board[r][c] = letters[index]
            }
            return true
        }

        return false
    }
}

private enum HostMaintenance {
    private static let suite = "group.com.pedrocarrasco.miapp"
    private static let widgetKind = "WordSearchWidget"
    private static let resetRequestKey = "puzzle_reset_request_v1"

    static func resetCurrentPuzzle() {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: resetRequestKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func applyGridSize(_ gridSize: Int) {
        HostDifficultySettings.setGridSize(gridSize)
        resetCurrentPuzzle()
    }

    static func applyAppearance(_ mode: HostAppearanceMode) {
        HostAppearanceSettings.setMode(mode)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func applyWordHintMode(_ mode: HostWordHintMode) {
        HostWordHintSettings.setMode(mode)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

#Preview {
    ContentView()
}
