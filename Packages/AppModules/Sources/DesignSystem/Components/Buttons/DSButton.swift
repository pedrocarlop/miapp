/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Buttons/DSButton.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSButton
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

public struct DSButton: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }

    private let title: String
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(TypographyTokens.bodyStrong)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, SpacingTokens.md)
                .padding(.vertical, SpacingTokens.sm)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous)
                        .fill(backgroundStyle)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return ColorTokens.surfacePaper
        case .secondary:
            return ColorTokens.inkPrimary
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(ThemeGradients.brushWarm)
        case .secondary:
            return AnyShapeStyle(ColorTokens.surfacePaper)
        case .destructive:
            return AnyShapeStyle(ColorTokens.error)
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return ColorTokens.borderSoft.opacity(0.35)
        case .secondary:
            return ColorTokens.borderSoft
        case .destructive:
            return ColorTokens.error.opacity(0.5)
        }
    }
}
