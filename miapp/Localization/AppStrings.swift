/*
 BEGINNER NOTES (AUTO):
 - Archivo: miapp/Localization/AppStrings.swift
 - Rol principal: Centraliza textos traducibles y acceso seguro a mensajes de UI.
 - Flujo simplificado: Entrada: clave de texto e idioma activo. | Proceso: resolver recurso localizado. | Salida: string final para mostrar en UI.
 - Tipos clave en este archivo: AppStrings
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

enum AppStrings {
    static var homeTitle: String {
        localized("app.home.title", default: "Sopa diaria")
    }

    static func completedCounterAccessibility(_ value: Int) -> String {
        String(
            format: localized("app.counter.completed.accessibility", default: "Retos completados %d"),
            locale: AppLocalization.currentLocale,
            value
        )
    }

    static var completedCounterHint: String {
        localized("app.counter.completed.hint", default: "Pulsa para saber que mide este contador")
    }

    static func streakCounterAccessibility(_ value: Int) -> String {
        String(
            format: localized("app.counter.streak.accessibility", default: "Racha actual %d"),
            locale: AppLocalization.currentLocale,
            value
        )
    }

    static var streakCounterHint: String {
        localized("app.counter.streak.hint", default: "Pulsa para saber que mide este contador")
    }

    static var openSettingsAccessibility: String {
        localized("app.settings.open_accessibility", default: "Abrir ajustes")
    }

    private static func localized(_ key: String, default value: String) -> String {
        AppLocalization.localized(key, default: value, bundle: .main)
    }
}
