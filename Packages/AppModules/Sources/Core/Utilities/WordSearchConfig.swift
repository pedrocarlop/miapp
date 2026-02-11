/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Utilities/WordSearchConfig.swift
 - Rol principal: Funciones auxiliares compartidas para evitar duplicar logica transversal.
 - Flujo simplificado: Entrada: parametros concretos. | Proceso: calculo helper acotado. | Salida: valor util para otras capas.
 - Tipos clave en este archivo: WordSearchConfig
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

public enum WordSearchConfig {
    public static let suiteName = "group.com.pedrocarrasco.miapp"
    public static let widgetKind = "WordSearchWidget"

    public static let stateKey = "puzzle_state_v3"
    public static let rotationBoundaryKey = "puzzle_rotation_boundary_v3"
    public static let resetRequestKey = "puzzle_reset_request_v1"
    public static let lastAppliedResetKey = "puzzle_last_applied_reset_v1"

    public static let appProgressKey = "puzzle_app_progress_v1"
    public static let completedOffsetsKey = "puzzle_completed_offsets_v1"
    public static let streakCurrentKey = "puzzle_streak_current_v1"
    public static let streakLastCompletedKey = "puzzle_streak_last_completed_v1"

    public static let hintAvailableKey = "puzzle_hint_available_v1"
    public static let hintRechargeKey = "puzzle_hint_recharge_v1"
    public static let hintRewardKey = "puzzle_hint_reward_v1"

    public static let appearanceModeKey = "puzzle_theme_mode_v1"
    public static let gridSizeKey = "puzzle_grid_size_v1"
    public static let wordHintModeKey = "puzzle_word_hint_mode_v1"
    public static let appLanguageKey = "puzzle_app_language_v1"
    public static let dailyRefreshMinutesKey = "puzzle_daily_refresh_minutes_v1"

    public static let enableCelebrationsKey = "puzzle_celebrations_enabled_v1"
    public static let enableHapticsKey = "puzzle_celebrations_haptics_v1"
    public static let enableSoundKey = "puzzle_celebrations_sound_v1"
    public static let intensityKey = "puzzle_celebrations_intensity_v1"

    public static let installDateKey = "puzzle_installation_date_v1"

    public static let legacyStateKey = "puzzle_state_v1"
    public static let legacyMigrationFlagKey = "puzzle_v2_migrated_legacy"
    public static let legacySlotStateKeys = [
        "puzzle_state_v2_a",
        "puzzle_state_v2_b",
        "puzzle_state_v2_c"
    ]
    public static let legacySlotIndexKeys = [
        "puzzle_index_v2_a",
        "puzzle_index_v2_b",
        "puzzle_index_v2_c"
    ]

    public static let minGridSize = 7
    public static let maxGridSize = 12

    public static let defaultDailyRefreshMinutes = 9 * 60
    public static let maxMinutesFromMidnight = 23 * 60 + 59

    public static let initialHints = 3
    public static let dailyHintRecharge = 1
    public static let completionHintReward = 1
    public static let maxHints = 10
}
