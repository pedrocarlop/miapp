/*
 BEGINNER NOTES (AUTO):
 - Archivo: WordSearchWidgetExtension/WordSearchWidgetAppearance.swift
 - Rol principal: Logica y UI del widget/intent extension fuera de la app principal.
 - Flujo simplificado: Entrada: timeline/intents/configuracion. | Proceso: resolver datos y layout del widget. | Salida: snapshot o vista del widget.
 - Tipos clave en este archivo: WordSearchWidgetColorTokens,WordSearchWidgetTypographyTokens WordSearchWidgetAppearanceMode
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

import SwiftUI
import DesignSystem
import Core

@available(iOS 17.0, *)
enum WordSearchWidgetColorTokens {
    static func widgetBackground(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    ColorTokens.surfaceSecondary,
                    ColorTokens.surfaceTertiary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                ColorTokens.backgroundPrimary,
                ColorTokens.surfaceSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func hintBlockingOverlay(isDark: Bool) -> Color {
        ColorTokens.surfaceSecondary.opacity(isDark ? 0.55 : 0.35)
    }

    static let hintCTA = ColorTokens.accentPrimary
    static let hintPanelStroke = ColorTokens.borderDefault
    static let completionOverlay = ColorTokens.surfaceSecondary.opacity(0.45)
}

@available(iOS 17.0, *)
enum WordSearchWidgetTypographyTokens {
    static let body = TypographyTokens.body
    static let overlayTitle = TypographyTokens.screenTitle.weight(.bold)
    static let overlayBody = TypographyTokens.caption
    static let hintTitle = TypographyTokens.caption.weight(.semibold)
    static let hintBody = TypographyTokens.bodyStrong
    static let hintCTA = TypographyTokens.footnote.weight(.semibold)
}

@available(iOS 17.0, *)
enum WordSearchWidgetAppearanceMode: String {
    case system
    case light
    case dark

    static func current() -> WordSearchWidgetAppearanceMode {
        switch WordSearchWidgetContainer.shared.settings().appearanceMode {
        case .system:
            return .system
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
