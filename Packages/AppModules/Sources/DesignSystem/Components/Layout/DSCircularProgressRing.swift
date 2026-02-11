/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Layout/DSCircularProgressRing.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSCircularProgressRing
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

public struct DSCircularProgressRing: View {
    public let progress: Double
    public let lineWidth: CGFloat
    public let size: CGFloat

    public init(
        progress: Double,
        lineWidth: CGFloat = 2,
        size: CGFloat = 14
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }

    public var body: some View {
        let clamped = min(max(progress, 0), 1)

        ZStack {
            Circle()
                .dsInnerStroke(ColorTokens.gridLine.opacity(0.75), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .dsInnerStroke(
                    ThemeGradients.brushWarm,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: MotionTokens.fastDuration), value: clamped)
    }
}
