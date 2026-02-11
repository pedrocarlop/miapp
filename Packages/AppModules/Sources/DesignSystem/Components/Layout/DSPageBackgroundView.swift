/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Layout/DSPageBackgroundView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: DSPageBackgroundView
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

public struct DSPageBackgroundView: View {
    private let gridSpacing: CGFloat
    private let gridOpacity: Double

    public init(
        gridSpacing: CGFloat = SpacingTokens.xxxl,
        gridOpacity: Double = 0.08
    ) {
        self.gridSpacing = gridSpacing
        self.gridOpacity = gridOpacity
    }

    public var body: some View {
        ZStack {
            ThemeGradients.paperBackground
                .ignoresSafeArea()

            DSGridBackgroundView(spacing: gridSpacing, opacity: gridOpacity)
                .ignoresSafeArea()
        }
    }
}
