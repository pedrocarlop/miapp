/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureDailyPuzzle/Presentation/Views/DailyPuzzleLoupeView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DailyPuzzleLoupeView
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
import Core
import DesignSystem

struct DailyPuzzleLoupeView<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @Binding var state: LoupeState
    let configuration: LoupeConfiguration
    let boardSize: CGSize
    let content: Content

    init(
        state: Binding<LoupeState>,
        configuration: LoupeConfiguration,
        boardSize: CGSize,
        @ViewBuilder content: () -> Content
    ) {
        _state = state
        self.configuration = configuration
        self.boardSize = boardSize
        self.content = content()
    }

    var body: some View {
        if state.isVisible {
            let shape = RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
            let size = state.loupeSize
            let offsetX = -state.fingerLocation.x * state.magnification + size.width / 2
            let offsetY = -state.fingerLocation.y * state.magnification + size.height / 2

            ZStack {
                shape
                    .fill(
                        reduceTransparency
                        ? AnyShapeStyle(ColorTokens.surfaceTertiary)
                        : AnyShapeStyle(.thinMaterial)
                    )

                content
                    .frame(width: boardSize.width, height: boardSize.height, alignment: .topLeading)
                    .scaleEffect(state.magnification, anchor: .topLeading)
                    .offset(x: offsetX, y: offsetY)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .clipShape(shape)
            }
            .frame(width: size.width, height: size.height)
            .overlay(
                shape.stroke(
                    colorSchemeContrast == .increased
                    ? ColorTokens.textPrimary.opacity(0.45)
                    : ColorTokens.textSecondary.opacity(0.22),
                    lineWidth: configuration.borderWidth
                )
            )
            .position(state.loupeScreenPosition)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}
