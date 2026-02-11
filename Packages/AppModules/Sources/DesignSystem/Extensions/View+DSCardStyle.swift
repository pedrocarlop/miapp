/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Extensions/View+DSCardStyle.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: (sin tipos principales declarados en este archivo; puede contener extensiones o constantes)
 - Funciones clave en este archivo: dsCardStyle
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

public extension View {
    func dsCardStyle() -> some View {
        padding(SpacingTokens.md)
            .background(
                RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous)
                    .fill(ColorTokens.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.cardRadius, style: .continuous)
                    .stroke(ColorTokens.borderSoft, lineWidth: 1)
            )
    }
}
