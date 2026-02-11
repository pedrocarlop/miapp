/*
 BEGINNER NOTES (AUTO):
 - Archivo: WordSearchWidgetExtension/WordSearchIntents.swift
 - Rol principal: Logica y UI del widget/intent extension fuera de la app principal.
 - Flujo simplificado: Entrada: timeline/intents/configuracion. | Proceso: resolver datos y layout del widget. | Salida: snapshot o vista del widget.
 - Tipos clave en este archivo: ToggleCellIntent,ToggleHelpIntent DismissHintIntent,WordSearchConstants
 - Funciones clave en este archivo: perform,perform perform
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
        await MainActor.run {
            WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct ToggleHelpIntent: AppIntent {
    static var title: LocalizedStringResource = "Mostrar ayuda"

    init() {}

    func perform() async throws -> some IntentResult {
        _ = WordSearchWidgetContainer.shared.toggleHelp(now: Date())
        await MainActor.run {
            WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct DismissHintIntent: AppIntent {
    static var title: LocalizedStringResource = "Ocultar pista"

    init() {}

    func perform() async throws -> some IntentResult {
        _ = WordSearchWidgetContainer.shared.dismissHint(now: Date())
        await MainActor.run {
            WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        }
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
        formatter.locale = AppLocalization.currentLocale
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
