/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureSettings/Presentation/Localization/SettingsStrings.swift
 - Rol principal: Centraliza textos traducibles y acceso seguro a mensajes de UI.
 - Flujo simplificado: Entrada: clave de texto e idioma activo. | Proceso: resolver recurso localizado. | Salida: string final para mostrar en UI.
 - Tipos clave en este archivo: SettingsStrings
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

public enum SettingsStrings {
    public static var title: String { localized("settings.title", default: "Ajustes") }

    public static var difficultySection: String { localized("settings.section.difficulty", default: "Dificultad") }
    public static var appearanceSection: String { localized("settings.section.appearance", default: "Apariencia") }
    public static var languageSection: String { localized("settings.section.language", default: "Idioma") }
    public static var hintsSection: String { localized("settings.section.hints", default: "Pistas") }
    public static var scheduleSection: String { localized("settings.section.schedule", default: "Horario") }
    public static var celebrationsSection: String { localized("settings.section.celebrations", default: "Celebraciones") }

    public static func gridSize(_ value: Int) -> String {
        String(
            format: localized("settings.grid_size", default: "Tamano de sopa: %1$dx%1$d"),
            locale: AppLocalization.currentLocale,
            value
        )
    }

    public static var difficultyHintPrimary: String {
        localized(
            "settings.difficulty.hint_primary",
            default: "A mayor tamano, mas dificultad. En el widget las letras y el area tactil se reducen para que entre la cuadricula."
        )
    }

    public static var difficultyHintSecondary: String {
        localized(
            "settings.difficulty.hint_secondary",
            default: "El nuevo tamano solo se aplica a retos futuros. Los retos ya creados mantienen su tamano para no perder progreso."
        )
    }

    public static var themePickerTitle: String { localized("settings.theme.title", default: "Tema") }
    public static var languagePickerTitle: String { localized("settings.language.title", default: "Idioma") }
    public static var languageDeviceManagedTitle: String {
        localized("settings.language.device_managed.title", default: "Idioma del dispositivo")
    }
    public static var languageDeviceManagedMessage: String {
        localized(
            "settings.language.device_managed.message",
            default: "Usamos la misma configuración de idiomas que tu teléfono móvil. Puedes cambiarla directamente desde la sección de ajustes de tu dispositivo."
        )
    }
    public static var languageOpenSettings: String {
        localized("settings.language.device_managed.open_settings", default: "Ir a ajustes")
    }
    public static var hintModePickerTitle: String { localized("settings.hints.mode", default: "Modo") }

    public static var definitionHint: String {
        localized("settings.hints.definition_info", default: "En definicion, veras la descripcion sin mostrar la palabra.")
    }

    public static var refreshPickerTitle: String { localized("settings.schedule.refresh", default: "Nueva sopa del dia") }
    public static var refreshHint: String { localized("settings.schedule.hint", default: "Por defecto se renueva a las 09:00.") }

    public static var celebrationsToggle: String { localized("settings.celebrations.toggle", default: "Animaciones de celebracion") }
    public static var hapticsToggle: String { localized("settings.celebrations.haptics", default: "Haptics") }
    public static var soundToggle: String { localized("settings.celebrations.sound", default: "Sonido") }
    public static var intensityPickerTitle: String { localized("settings.celebrations.intensity", default: "Intensidad") }

    public static var reduceMotionHint: String {
        localized("settings.celebrations.reduce_motion_hint", default: "Si Reduce Motion esta activo, se desactivan las particulas.")
    }

    public static var cancel: String { localized("settings.action.cancel", default: "Cancelar") }
    public static var save: String { localized("settings.action.save", default: "Guardar") }

    public static func appearanceTitle(for mode: AppearanceMode) -> String {
        switch mode {
        case .system:
            return localized("settings.appearance.system", default: "Sistema")
        case .light:
            return localized("settings.appearance.light", default: "Claro")
        case .dark:
            return localized("settings.appearance.dark", default: "Oscuro")
        }
    }

    public static func wordHintTitle(for mode: WordHintMode) -> String {
        switch mode {
        case .word:
            return localized("settings.word_hint.word", default: "Palabra")
        case .definition:
            return localized("settings.word_hint.definition", default: "Definicion")
        }
    }

    public static func languageTitle(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return localized("settings.language.english", default: "English")
        case .spanish:
            return localized("settings.language.spanish", default: "Español")
        case .french:
            return localized("settings.language.french", default: "Français")
        case .portuguese:
            return localized("settings.language.portuguese", default: "Português")
        }
    }

    public static func celebrationTitle(for intensity: CelebrationIntensity) -> String {
        switch intensity {
        case .low:
            return localized("settings.celebration.low", default: "Baja")
        case .medium:
            return localized("settings.celebration.medium", default: "Media")
        case .high:
            return localized("settings.celebration.high", default: "Alta")
        }
    }

    private static func localized(_ key: String, default value: String) -> String {
        AppLocalization.localized(key, default: value, bundle: .module)
    }
}
