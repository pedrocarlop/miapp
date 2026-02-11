/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureHistory/Presentation/Localization/HistoryStrings.swift
 - Rol principal: Centraliza textos traducibles y acceso seguro a mensajes de UI.
 - Flujo simplificado: Entrada: clave de texto e idioma activo. | Proceso: resolver recurso localizado. | Salida: string final para mostrar en UI.
 - Tipos clave en este archivo: HistoryStrings
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

public enum HistoryStrings {
    public static var completedPuzzlesTitle: String {
        localized("history.completed.title", default: "Puzzles completados")
    }

    public static var streakTitle: String {
        localized("history.streak.title", default: "Racha actual")
    }

    public static var completedPuzzlesExplanation: String {
        localized(
            "history.completed.explanation",
            default: "Muestra cuantos retos diarios has terminado en total desde que instalaste la app."
        )
    }

    public static var streakExplanation: String {
        localized(
            "history.streak.explanation",
            default: "Cuenta los dias seguidos en los que completas el reto del dia actual. Si un dia no lo completas, la racha se reinicia."
        )
    }

    private static func localized(_ key: String, default value: String) -> String {
        AppLocalization.localized(key, default: value, bundle: .module)
    }
}
