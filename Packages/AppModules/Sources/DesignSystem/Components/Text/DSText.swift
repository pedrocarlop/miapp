/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Text/DSText.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSText
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

public struct DSText: View {
    public enum Style {
        case titleLarge
        case titleMedium
        case titleSmall
        case body
        case bodyStrong
        case footnote
        case caption
    }

    private let value: String
    private let style: Style
    private let color: Color

    public init(_ value: String, style: Style = .body, color: Color = ColorTokens.textPrimary) {
        self.value = value
        self.style = style
        self.color = color
    }

    public var body: some View {
        Text(value)
            .font(font)
            .foregroundStyle(color)
    }

    private var font: Font {
        switch style {
        case .titleLarge:
            return TypographyTokens.titleLarge
        case .titleMedium:
            return TypographyTokens.titleMedium
        case .titleSmall:
            return TypographyTokens.titleSmall
        case .body:
            return TypographyTokens.body
        case .bodyStrong:
            return TypographyTokens.bodyStrong
        case .footnote:
            return TypographyTokens.footnote
        case .caption:
            return TypographyTokens.caption
        }
    }
}
