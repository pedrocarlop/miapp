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

struct DailyPuzzleLoupeView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @Binding var state: LoupeState
    let configuration: LoupeConfiguration
    let boardSize: CGSize
    let selectedText: String
    let shouldAvoidTopRowFingerOverlap: Bool

    init(
        state: Binding<LoupeState>,
        configuration: LoupeConfiguration,
        boardSize: CGSize,
        selectedText: String,
        shouldAvoidTopRowFingerOverlap: Bool
    ) {
        _state = state
        self.configuration = configuration
        self.boardSize = boardSize
        self.selectedText = selectedText
        self.shouldAvoidTopRowFingerOverlap = shouldAvoidTopRowFingerOverlap
    }

    var body: some View {
        GeometryReader { proxy in
            if state.isVisible {
                let bubbleShape = Capsule(style: .continuous)
                let bubbleText = selectedText.isEmpty ? " " : selectedText

                Text(bubbleText)
                    .font(TypographyTokens.bodyStrong)
                    .foregroundStyle(ColorTokens.inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, SpacingTokens.md)
                    .padding(.vertical, SpacingTokens.xs)
                    .background(
                        bubbleShape.fill(
                            reduceTransparency
                            ? AnyShapeStyle(ColorTokens.surfaceTertiary)
                            : AnyShapeStyle(.thinMaterial)
                        )
                    )
                    .overlay(
                        bubbleShape.dsInnerStroke(
                            colorSchemeContrast == .increased
                            ? ColorTokens.textPrimary.opacity(0.45)
                            : ColorTokens.textSecondary.opacity(0.24),
                            lineWidth: configuration.borderWidth
                        )
                    )
                    .shadow(
                        color: colorSchemeContrast == .increased
                        ? ColorTokens.textPrimary.opacity(0.16)
                        : ColorTokens.textPrimary.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .position(displayPosition(in: proxy))
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
    }

    private func displayPosition(in proxy: GeometryProxy) -> CGPoint {
        let topClampY = state.loupeSize.height * 0.5 + configuration.edgePadding
        let isPinnedToTop = state.loupeScreenPosition.y <= topClampY + 0.5
        guard shouldAvoidTopRowFingerOverlap && isPinnedToTop else {
            return state.loupeScreenPosition
        }

        let bubbleHeight = state.loupeSize.height
        let outsideCenterY = -(bubbleHeight * 0.5 + configuration.edgePadding)
        let boardFrameGlobal = proxy.frame(in: .global)
        let availableTopSpace = boardFrameGlobal.minY - proxy.safeAreaInsets.top
        let canPlaceOutsideTop = availableTopSpace >= bubbleHeight + configuration.edgePadding

        if canPlaceOutsideTop {
            return CGPoint(x: state.loupeScreenPosition.x, y: outsideCenterY)
        }

        let minCenterX = state.loupeSize.width * 0.5 + configuration.edgePadding
        let maxCenterX = max(minCenterX, boardSize.width - minCenterX)
        let sideOffset = state.loupeSize.width * 0.62
        let desiredLeftX = state.fingerLocation.x - sideOffset
        let useRight = desiredLeftX <= minCenterX + 1
        let candidateX = useRight ? state.fingerLocation.x + sideOffset : desiredLeftX
        let clampedX = min(max(candidateX, minCenterX), maxCenterX)
        let clampedY = min(
            max(state.loupeScreenPosition.y, topClampY),
            max(topClampY, boardSize.height - topClampY)
        )

        return CGPoint(x: clampedX, y: clampedY)
    }
}
