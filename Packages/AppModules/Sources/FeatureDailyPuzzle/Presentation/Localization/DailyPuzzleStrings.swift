/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Localization/DailyPuzzleStrings.swift
 - Rol principal: Centraliza textos traducibles y acceso seguro a mensajes de UI.
 - Flujo simplificado: Entrada: clave de texto e idioma activo. | Proceso: resolver recurso localizado. | Salida: string final para mostrar en UI.
 - Tipos clave en este archivo: DailyPuzzleStrings
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

import Foundation
import Core

public enum DailyPuzzleStrings {
    public static var completed: String {
        localized("daily.completed", default: "Completado")
    }

    public static var completionCelebrationTitle: String {
        localized("daily.completion.title", default: "Reto completado")
    }

    public static var completionCelebrationMessage: String {
        localized("daily.completion.message", default: "Encontraste todas las palabras de hoy. Gran jugada.")
    }

    public static var completionContinueAction: String {
        localized("daily.completion.action_continue", default: "Continuar")
    }

    public static func challengeProgress(found: Int, total: Int) -> String {
        String(
            format: localized("daily.challenge.progress", default: "%d de %d completadas"),
            locale: AppLocalization.currentLocale,
            found,
            total
        )
    }

    public static func challengeAvailableIn(hours: Int) -> String {
        String(
            format: localized("daily.challenge.available_in_hours", default: "Disponible en %dh"),
            locale: AppLocalization.currentLocale,
            hours
        )
    }

    public static var challengeAvailableSoon: String {
        localized("daily.challenge.available_soon", default: "Disponible pronto")
    }

    public static func challengeAccessibilityLabel(number: Int, status: String) -> String {
        String(
            format: localized("daily.challenge.accessibility", default: "Reto %d, %@"),
            locale: AppLocalization.currentLocale,
            number,
            status
        )
    }

    public static var close: String {
        localized("daily.action.close", default: "Cerrar")
    }

    public static var resetChallenge: String {
        localized("daily.action.reset", default: "Reiniciar reto")
    }

    public static var playChallenge: String {
        localized("daily.action.play", default: "Jugar")
    }

    public static var rotateBoard: String {
        localized("daily.action.rotate_board", default: "Rotar tablero")
    }

    public static var rotateBoardHint: String {
        localized(
            "daily.action.rotate_board_hint",
            default: "Rota la sopa de letras noventa grados en sentido antihorario."
        )
    }

    public static var resetAlertTitle: String {
        localized("daily.reset_alert.title", default: "Reiniciar reto")
    }

    public static var resetAlertCancel: String {
        localized("daily.reset_alert.cancel", default: "Cancelar")
    }

    public static var resetAlertConfirm: String {
        localized("daily.reset_alert.confirm", default: "Reiniciar")
    }

    public static var resetAlertMessage: String {
        localized("daily.reset_alert.message", default: "Se borrara el progreso de este dia.")
    }

    public static func streakLabel(_ value: Int) -> String {
        String(
            format: localized("daily.streak_label", default: "Racha %d"),
            locale: AppLocalization.currentLocale,
            value
        )
    }

    public static func completionAccessibility(_ streakLabel: String?) -> String {
        if let streakLabel {
            return String(
                format: localized("daily.completion.accessibility_with_streak", default: "Completado. %@"),
                locale: AppLocalization.currentLocale,
                streakLabel
            )
        }
        return localized("daily.completion.accessibility", default: "Completado")
    }

    public static func hoursShort(_ value: Int) -> String {
        String(
            format: localized("daily.hours_short", default: "%dh"),
            locale: AppLocalization.currentLocale,
            value
        )
    }

    public static func wordFeedbackMessage(at index: Int) -> String {
        let messages = [
            localized("daily.word_feedback.1", default: "Buen trabajo"),
            localized("daily.word_feedback.2", default: "Excelente"),
            localized("daily.word_feedback.3", default: "Muy bien"),
            localized("daily.word_feedback.4", default: "Sigue asi"),
            localized("daily.word_feedback.5", default: "Perfecto"),
            localized("daily.word_feedback.6", default: "Gran jugada")
        ]

        guard !messages.isEmpty else {
            return localized("daily.word_feedback.fallback", default: "Buen trabajo")
        }

        let safeIndex = ((index % messages.count) + messages.count) % messages.count
        return messages[safeIndex]
    }

    private static func localized(_ key: String, default value: String) -> String {
        AppLocalization.localized(key, default: value, bundle: .module)
    }
}
