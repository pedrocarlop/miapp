//
//  WordSearchIntents.swift
//  WordSearchWidgetExtension
//

import Foundation
import AppIntents
import WidgetKit
import Core

@available(iOS 17.0, *)
struct ToggleCellIntent: AppIntent {
    static var title: LocalizedStringResource = "Seleccionar letras"

    @Parameter(title: "Fila") var row: Int
    @Parameter(title: "Columna") var col: Int

    init() {}

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    func perform() async throws -> some IntentResult {
        _ = WordSearchWidgetContainer.shared.applyTap(row: row, col: col, now: Date())
        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        return .result()
    }
}

@available(iOS 17.0, *)
struct ToggleHelpIntent: AppIntent {
    static var title: LocalizedStringResource = "Mostrar ayuda"

    init() {}

    func perform() async throws -> some IntentResult {
        _ = WordSearchWidgetContainer.shared.toggleHelp(now: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        return .result()
    }
}

@available(iOS 17.0, *)
struct DismissHintIntent: AppIntent {
    static var title: LocalizedStringResource = "Ocultar pista"

    init() {}

    func perform() async throws -> some IntentResult {
        _ = WordSearchWidgetContainer.shared.dismissHint(now: Date())

        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        return .result()
    }
}

@available(iOS 17.0, *)
enum WordSearchConstants {
    static let widgetKind = WordSearchConfig.widgetKind
}

@available(iOS 17.0, *)
enum WordSearchDailyRefreshSettings {
    static func minutesFromMidnight() -> Int {
        WordSearchWidgetContainer.shared.settings().dailyRefreshMinutes
    }

    static func date(for minutesFromMidnight: Int, reference: Date) -> Date {
        DailyRefreshClock.date(for: minutesFromMidnight, reference: reference)
    }

    static func formattedTimeLabel() -> String {
        let boundary = date(for: minutesFromMidnight(), reference: Date())
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: boundary)
    }
}

@available(iOS 17.0, *)
enum WordSearchHintMode: String, CaseIterable, Identifiable {
    case word
    case definition

    var id: String { rawValue }

    static func current() -> WordSearchHintMode {
        WordSearchWidgetContainer.shared.settings().wordHintMode == .word ? .word : .definition
    }

    var coreMode: WordHintMode {
        switch self {
        case .word: return .word
        case .definition: return .definition
        }
    }
}

@available(iOS 17.0, *)
enum WordSearchWordHints {
    static func displayText(for word: String, mode: WordSearchHintMode) -> String {
        WordHintsService.displayText(for: word, mode: mode.coreMode)
    }
}

@available(iOS 17.0, *)
typealias WordSearchPosition = GridPosition

@available(iOS 17.0, *)
typealias WordSearchState = SharedPuzzleState

@available(iOS 17.0, *)
enum WordSearchPersistence {
    static func loadState(at now: Date = Date()) -> WordSearchState {
        WordSearchWidgetContainer.shared.loadState(now: now)
    }

    static func nextRefreshDate(from now: Date, state: WordSearchState) -> Date {
        var refreshAt = nextDailyRefreshDate(after: now)
        if let feedback = state.feedback, feedback.expiresAt > now {
            refreshAt = min(refreshAt, feedback.expiresAt)
        }
        if let hintExpiry = state.nextHintExpiresAt, hintExpiry > now {
            refreshAt = min(refreshAt, hintExpiry)
        }
        return refreshAt
    }

    static func nextDailyRefreshDate(after now: Date) -> Date {
        DailyRefreshClock.nextDailyRefreshDate(
            after: now,
            minutesFromMidnight: WordSearchDailyRefreshSettings.minutesFromMidnight()
        )
    }
}
