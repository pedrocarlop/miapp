/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureHistory/Presentation/Views/HistoryNavCounterView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: HistoryNavCounterView
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

public struct HistoryNavCounterView: View {
    public let value: Int
    public let systemImage: String
    public let iconGradient: LinearGradient
    public let accessibilityLabel: String
    public let accessibilityHint: String
    public let action: () -> Void

    public init(
        value: Int,
        systemImage: String,
        iconGradient: LinearGradient,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) {
        self.value = value
        self.systemImage = systemImage
        self.iconGradient = iconGradient
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingTokens.xxs) {
                Image(systemName: systemImage)
                    .font(TypographyTokens.caption.weight(.semibold))
                    .foregroundStyle(iconGradient)
                Text("\(value)")
                    .font(TypographyTokens.caption.weight(.semibold))
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}
