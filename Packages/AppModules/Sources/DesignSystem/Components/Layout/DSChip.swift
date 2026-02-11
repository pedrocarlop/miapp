/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Layout/DSChip.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSChip
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

public struct DSChip: View {
    private let text: String
    private let isSelected: Bool

    public init(text: String, isSelected: Bool = false) {
        self.text = text
        self.isSelected = isSelected
    }

    public var body: some View {
        Text(text)
            .font(TypographyTokens.caption)
            .foregroundStyle(ColorTokens.inkPrimary)
            .padding(.horizontal, SpacingTokens.sm)
            .padding(.vertical, SpacingTokens.xs)
            .background(
                RoundedRectangle(cornerRadius: RadiusTokens.chipRadius, style: .continuous)
                    .fill(fillStyle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.chipRadius, style: .continuous)
                    .stroke(ColorTokens.chipBorder, lineWidth: 1)
            )
    }

    private var fillStyle: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(ThemeGradients.brushWarm.opacity(0.2))
        }
        return AnyShapeStyle(ColorTokens.chipNeutralFill)
    }
}
