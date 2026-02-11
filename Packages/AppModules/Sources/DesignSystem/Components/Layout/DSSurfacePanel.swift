/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Layout/DSSurfacePanel.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSSurfacePanel
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

public struct DSSurfacePanel<Content: View>: View {
    private let cornerRadius: CGFloat
    private let lineWidth: CGFloat
    private let reduceTransparency: Bool
    private let content: Content

    public init(
        cornerRadius: CGFloat = RadiusTokens.overlayRadius,
        lineWidth: CGFloat = 1,
        reduceTransparency: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.reduceTransparency = reduceTransparency
        self.content = content()
    }

    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        reduceTransparency
                            ? AnyShapeStyle(ColorTokens.surfaceSecondary)
                            : AnyShapeStyle(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .dsInnerStroke(ColorTokens.textPrimary.opacity(0.24), lineWidth: lineWidth)
            )
    }
}
