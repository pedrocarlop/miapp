/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/ViewModels/DailyPuzzleHomeScreenViewModel.swift
 - Rol principal: Coordina estado de pantalla: recibe acciones, llama casos de uso y actualiza modelo de UI.
 - Flujo simplificado: Entrada: accion de la vista o carga inicial. | Proceso: valida, invoca servicios/use cases, transforma resultados. | Salida: nuevo estado de UI.
 - Tipos clave en este archivo: DailyPuzzleProgressSnapshot,DailyPuzzleChallengeTapAction DailyPuzzleChallengeCardState,DailyPuzzleHomeScreenViewModel
 - Funciones clave en este archivo: setSelectedOffset,selectTodayIfNeeded clampSelectedOffsetIfNeeded,refresh puzzleDate,isLocked
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

import Foundation
import Observation
import Core

public struct DailyPuzzleProgressSnapshot: Equatable, Sendable {
    public let foundWords: Set<String>
    public let solvedPositions: Set<GridPosition>

    public init(foundWords: Set<String>, solvedPositions: Set<GridPosition>) {
        self.foundWords = foundWords
        self.solvedPositions = solvedPositions
    }

    public static let empty = DailyPuzzleProgressSnapshot(
        foundWords: [],
        solvedPositions: []
    )
}

public enum DailyPuzzleChallengeTapAction: Equatable, Sendable {
    case openGame
    case unlocked
    case noAction
}

public struct DailyPuzzleChallengeCardState: Identifiable, Equatable, Sendable {
    public let offset: Int
    public let date: Date
    public let puzzleNumber: Int
    public let grid: [[String]]
    public let words: [String]
    public let progress: DailyPuzzleProgressSnapshot
    public let isLocked: Bool
    public let hoursUntilAvailable: Int?

    public init(
        offset: Int,
        date: Date,
        puzzleNumber: Int,
        grid: [[String]],
        words: [String],
        progress: DailyPuzzleProgressSnapshot,
        isLocked: Bool,
        hoursUntilAvailable: Int?
    ) {
        self.offset = offset
        self.date = date
        self.puzzleNumber = puzzleNumber
        self.grid = grid
        self.words = words
        self.progress = progress
        self.isLocked = isLocked
        self.hoursUntilAvailable = hoursUntilAvailable
    }

    public var id: Int { offset }
}

@Observable
@MainActor
public final class DailyPuzzleHomeScreenViewModel {
    private enum Constants {
        static let unlockTapThreshold = 10
        static let visibleOffsetsRadius = 2
        static let preferredVisibleOffsetsCount = 5
    }

    public private(set) var installDate: Date
    public private(set) var selectedOffset: Int?
    public private(set) var sharedState: SharedPuzzleState
    public private(set) var appProgressRecords: [String: AppProgressRecord]
    public private(set) var easterUnlockedOffsets: Set<Int> = []
    public private(set) var carouselOffsets: [Int] = []
    public private(set) var challengeCards: [DailyPuzzleChallengeCardState] = []

    private let core: CoreContainer
    private var referenceNow: Date
    private var easterTapCounts: [Int: Int] = [:]
    private var currentPreferredGridSize: Int

    public init(
        core: CoreContainer,
        preferredGridSize: Int,
        now: Date = Date()
    ) {
        self.core = core
        self.referenceNow = now
        self.currentPreferredGridSize = preferredGridSize
        self.installDate = core.installationDate()
        self.selectedOffset = nil
        self.sharedState = core.getSharedPuzzleStateUseCase.execute(
            now: now,
            preferredGridSize: preferredGridSize
        )
        self.appProgressRecords = core.loadAllProgressRecordsUseCase.execute()
        selectTodayIfNeeded()
        rebuildDerivedState(preferredGridSize: preferredGridSize, now: now)
    }

    public var todayOffset: Int {
        core.dayOffset(from: installDate, to: currentBoundary).offset
    }

    public var minOffset: Int { 0 }
    public var maxOffset: Int { todayOffset + 1 }

    public func setSelectedOffset(_ offset: Int?) {
        guard let offset else { return }
        let previousSelection = selectedOffset
        selectedOffset = clampedOffset(offset)
        clampSelectedOffsetIfNeeded()

        guard previousSelection != selectedOffset else { return }
        guard let selectedOffset else { return }
        guard shouldRebuildWindow(for: selectedOffset) else { return }
        rebuildDerivedState(
            preferredGridSize: currentPreferredGridSize,
            now: referenceNow
        )
    }

    public func selectTodayIfNeeded() {
        if selectedOffset == nil {
            selectedOffset = todayOffset
        }
        clampSelectedOffsetIfNeeded()
    }

    public func clampSelectedOffsetIfNeeded() {
        guard let selectedOffset else { return }
        self.selectedOffset = clampedOffset(selectedOffset)
    }

    public func refresh(
        preferredGridSize: Int,
        now: Date = Date()
    ) {
        currentPreferredGridSize = preferredGridSize
        referenceNow = now
        installDate = core.installationDate()
        sharedState = core.getSharedPuzzleStateUseCase.execute(
            now: now,
            preferredGridSize: preferredGridSize
        )
        appProgressRecords = core.loadAllProgressRecordsUseCase.execute()

        if sharedState.isCompleted {
            let todayKey = DayKey(offset: todayOffset)
            core.markCompletedDayUseCase.execute(dayKey: todayKey)
            _ = core.updateStreakUseCase.markCompleted(
                dayKey: todayKey,
                todayKey: todayKey
            )
            _ = core.rewardCompletionHintUseCase.execute(
                dayKey: todayKey,
                todayKey: todayKey
            )
        }

        selectTodayIfNeeded()
        rebuildDerivedState(preferredGridSize: preferredGridSize, now: now)
    }

    public func puzzleDate(for offset: Int) -> Date {
        let delta = offset - todayOffset
        return Calendar.current.date(byAdding: .day, value: delta, to: currentBoundary) ?? currentBoundary
    }

    public func isLocked(offset: Int) -> Bool {
        offset > todayOffset && !easterUnlockedOffsets.contains(offset)
    }

    public func handleChallengeCardTap(offset: Int) -> DailyPuzzleChallengeTapAction {
        if !isLocked(offset: offset) {
            return .openGame
        }

        let nextCount = (easterTapCounts[offset] ?? 0) + 1
        easterTapCounts[offset] = nextCount

        guard nextCount >= Constants.unlockTapThreshold else {
            return .noAction
        }

        easterUnlockedOffsets.insert(offset)
        easterTapCounts[offset] = 0
        rebuildChallengeCards(preferredGridSize: currentPreferredGridSize, now: referenceNow)
        return .unlocked
    }

    public func puzzleForOffset(_ offset: Int, preferredGridSize: Int) -> Puzzle {
        if offset == todayOffset, !sharedState.grid.isEmpty, !sharedState.words.isEmpty {
            return Puzzle(
                number: sharedState.puzzleIndex + 1,
                dayKey: DayKey(offset: offset),
                grid: PuzzleGrid(letters: sharedState.grid),
                words: sharedState.words.map(Word.init(text:))
            )
        }

        if let record = appProgressRecord(for: offset, preferredGridSize: preferredGridSize) {
            return core.puzzle(dayKey: DayKey(offset: offset), gridSize: record.gridSize)
        }

        return core.puzzle(dayKey: DayKey(offset: offset), gridSize: preferredGridSize)
    }

    public func progressForOffset(
        _ offset: Int,
        puzzle: Puzzle,
        preferredGridSize: Int
    ) -> DailyPuzzleProgressSnapshot {
        if offset == todayOffset {
            return progress(from: sharedState, puzzle: puzzle)
        }

        if let record = appProgressRecord(for: offset, preferredGridSize: preferredGridSize) {
            return progress(from: record, puzzle: puzzle)
        }

        return .empty
    }

    public func progressFraction(for offset: Int, preferredGridSize: Int) -> Double {
        if let cached = challengeCards.first(where: { $0.offset == offset }) {
            return progressFraction(
                progress: cached.progress,
                words: cached.words
            )
        }

        let puzzle = puzzleForOffset(offset, preferredGridSize: preferredGridSize)
        let progress = progressForOffset(offset, puzzle: puzzle, preferredGridSize: preferredGridSize)
        return progressFraction(
            progress: progress,
            words: puzzle.words.map(\.text)
        )
    }

    public func hoursUntilAvailable(for offset: Int, now: Date = Date()) -> Int? {
        guard offset > todayOffset else { return nil }
        let availableAt = puzzleDate(for: offset)
        let remaining = availableAt.timeIntervalSince(now)
        if remaining <= 0 {
            return 0
        }
        return Int(ceil(remaining / 3600))
    }

    public func initialProgressRecord(for offset: Int, preferredGridSize: Int) -> AppProgressRecord? {
        if offset == todayOffset {
            return appProgressRecord(
                from: sharedState,
                dayOffset: offset,
                gridSize: preferredGridSize
            )
        }
        return appProgressRecord(for: offset, preferredGridSize: preferredGridSize)
    }

    public func sharedPuzzleIndex(for offset: Int) -> Int? {
        offset == todayOffset ? sharedState.puzzleIndex : nil
    }

    private var currentBoundary: Date {
        core.currentRotationBoundaryUseCase.execute(now: referenceNow)
    }

    private func appProgressRecord(
        for offset: Int,
        preferredGridSize: Int
    ) -> AppProgressRecord? {
        ProgressRecordResolver.resolve(
            dayOffset: offset,
            preferredGridSize: preferredGridSize,
            records: appProgressRecords
        )
    }

    private func progress(
        from sharedState: SharedPuzzleState,
        puzzle: Puzzle
    ) -> DailyPuzzleProgressSnapshot {
        let puzzleWords = Set(puzzle.words.map(\.text))
        let normalizedFound = Set(sharedState.foundWords.map(WordSearchNormalization.normalizedWord))
            .intersection(puzzleWords)
        let normalizedPositions = Set(sharedState.solvedPositions.filter { puzzle.grid.contains($0) })
        return DailyPuzzleProgressSnapshot(
            foundWords: normalizedFound,
            solvedPositions: normalizedPositions
        )
    }

    private func progress(
        from record: AppProgressRecord,
        puzzle: Puzzle
    ) -> DailyPuzzleProgressSnapshot {
        let puzzleWords = Set(puzzle.words.map(\.text))
        let normalizedFound = Set(record.foundWords.map(WordSearchNormalization.normalizedWord))
            .intersection(puzzleWords)
        let normalizedPositions = Set(record.solvedPositions.filter { puzzle.grid.contains($0) })
        return DailyPuzzleProgressSnapshot(
            foundWords: normalizedFound,
            solvedPositions: normalizedPositions
        )
    }

    private func appProgressRecord(
        from sharedState: SharedPuzzleState,
        dayOffset: Int,
        gridSize: Int
    ) -> AppProgressRecord {
        AppProgressRecord(
            dayOffset: dayOffset,
            gridSize: gridSize,
            foundWords: Array(sharedState.foundWords),
            solvedPositions: Array(sharedState.solvedPositions),
            startedAt: nil,
            endedAt: nil
        )
    }

    private func rebuildDerivedState(preferredGridSize: Int, now: Date) {
        rebuildCarouselOffsets()
        rebuildChallengeCards(
            preferredGridSize: preferredGridSize,
            now: now
        )
    }

    private func rebuildCarouselOffsets() {
        let selected = activeOffsetForWindow
        guard
            let lower = carouselOffsets.first,
            let upper = carouselOffsets.last
        else {
            carouselOffsets = visibleOffsets(around: selected)
            return
        }

        let nextOffsets: [Int]
        if selected < lower || selected > upper {
            nextOffsets = visibleOffsets(around: selected)
        } else if selected == upper, upper < maxOffset {
            nextOffsets = shiftedWindow(by: 1, lower: lower, upper: upper)
        } else if selected == lower, lower > minOffset {
            nextOffsets = shiftedWindow(by: -1, lower: lower, upper: upper)
        } else {
            nextOffsets = carouselOffsets
        }

        guard carouselOffsets != nextOffsets else { return }
        carouselOffsets = nextOffsets
    }

    private func rebuildChallengeCards(
        preferredGridSize: Int,
        now: Date
    ) {
        challengeCards = carouselOffsets.map { offset in
            let puzzle = puzzleForOffset(offset, preferredGridSize: preferredGridSize)
            let progress = progressForOffset(
                offset,
                puzzle: puzzle,
                preferredGridSize: preferredGridSize
            )
            return DailyPuzzleChallengeCardState(
                offset: offset,
                date: puzzleDate(for: offset),
                puzzleNumber: puzzle.number,
                grid: puzzle.grid.letters,
                words: puzzle.words.map(\.text),
                progress: progress,
                isLocked: isLocked(offset: offset),
                hoursUntilAvailable: hoursUntilAvailable(for: offset, now: now)
            )
        }
    }

    private func progressFraction(
        progress: DailyPuzzleProgressSnapshot,
        words: [String]
    ) -> Double {
        let total = max(words.count, 1)
        let normalizedFound = Set(progress.foundWords.map { $0.uppercased() })
        let normalizedWords = Set(words.map { $0.uppercased() })
        let foundCount = normalizedFound.intersection(normalizedWords).count
        return min(max(Double(foundCount) / Double(total), 0), 1)
    }

    private func clampedOffset(_ offset: Int) -> Int {
        min(max(offset, minOffset), maxOffset)
    }

    private func shouldRebuildWindow(for selected: Int) -> Bool {
        guard let lower = carouselOffsets.first, let upper = carouselOffsets.last else {
            return true
        }
        if selected < lower || selected > upper {
            return true
        }
        return selected == lower || selected == upper
    }

    private var activeOffsetForWindow: Int {
        let fallback = selectedOffset ?? todayOffset
        return min(max(fallback, minOffset), maxOffset)
    }

    private func visibleOffsets(around centerOffset: Int) -> [Int] {
        guard minOffset <= maxOffset else { return [] }

        var lower = max(minOffset, centerOffset - Constants.visibleOffsetsRadius)
        var upper = min(maxOffset, centerOffset + Constants.visibleOffsetsRadius)

        while upper - lower + 1 < Constants.preferredVisibleOffsetsCount {
            if lower > minOffset {
                lower -= 1
                continue
            }
            if upper < maxOffset {
                upper += 1
                continue
            }
            break
        }

        return Array(lower...upper)
    }

    private func shiftedWindow(by delta: Int, lower: Int, upper: Int) -> [Int] {
        let count = max(upper - lower + 1, 1)
        if delta > 0 {
            let nextUpper = min(upper + 1, maxOffset)
            let nextLower = max(minOffset, nextUpper - (count - 1))
            return Array(nextLower...nextUpper)
        }

        let nextLower = max(lower - 1, minOffset)
        let nextUpper = min(maxOffset, nextLower + (count - 1))
        return Array(nextLower...nextUpper)
    }
}
