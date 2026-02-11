/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Inputs/DSTextInput.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSTextInput
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

public struct DSTextInput: View {
    private let title: String
    @Binding private var value: String

    public init(title: String, value: Binding<String>) {
        self.title = title
        self._value = value
    }

    public var body: some View {
        TextField(title, text: $value)
            .textFieldStyle(.plain)
            .font(TypographyTokens.body)
            .foregroundStyle(ColorTokens.inkPrimary)
            .padding(SpacingTokens.sm)
            .background(
                RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous)
                    .fill(ColorTokens.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous)
                    .stroke(ColorTokens.borderDefault, lineWidth: 1)
            )
    }
}
