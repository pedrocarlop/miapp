/*
 BEGINNER NOTES (AUTO):
 - Archivo: WordSearchWidgetExtension/Localization/WidgetStrings.swift
 - Rol principal: Centraliza textos traducibles y acceso seguro a mensajes de UI.
 - Flujo simplificado: Entrada: clave de texto e idioma activo. | Proceso: resolver recurso localizado. | Salida: string final para mostrar en UI.
 - Tipos clave en este archivo: WidgetStrings
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
import SwiftUI
import Core

enum WidgetStrings {
    static var nextLabel: String {
        localized("widget.next.label", default: "Siguiente:")
    }

    static var understoodAction: String {
        localized("widget.action.understood", default: "Entendido")
    }

    static var completedTitle: String {
        localized("widget.completed.title", default: "Completado")
    }

    static func completedMessage(nextRefreshTimeLabel: String) -> String {
        String(
            format: localized("widget.completed.message", default: "Manana a las %@ se cargara otra sopa de letras."),
            locale: AppLocalization.currentLocale,
            nextRefreshTimeLabel
        )
    }

    static var completedHint: String {
        localized("widget.completed.hint", default: "Cada dia se anade un nuevo juego.")
    }

    static var configurationDisplayName: String {
        localized("widget.configuration.display_name", default: "Sopa de letras")
    }

    static var configurationDescription: String {
        localized("widget.configuration.description", default: "Selecciona una letra inicial y una final para cada palabra.")
    }

    static var intentSelectLetters: LocalizedStringResource {
        LocalizedStringResource("widget.intent.select_letters")
    }

    static var intentRow: LocalizedStringResource {
        LocalizedStringResource("widget.intent.row")
    }

    static var intentColumn: LocalizedStringResource {
        LocalizedStringResource("widget.intent.column")
    }

    static var intentShowHelp: LocalizedStringResource {
        LocalizedStringResource("widget.intent.show_help")
    }

    static var intentHideHint: LocalizedStringResource {
        LocalizedStringResource("widget.intent.hide_hint")
    }

    private static func localized(_ key: String, default value: String) -> String {
        AppLocalization.localized(key, default: value, bundle: .main)
    }
}
