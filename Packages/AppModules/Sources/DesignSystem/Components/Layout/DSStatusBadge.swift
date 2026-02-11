/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Layout/DSStatusBadge.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSStatusBadge
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

public struct DSStatusBadge: View {
    public enum Kind {
        case locked
        case completed
    }

    private let kind: Kind
    private let size: CGFloat

    public init(kind: Kind, size: CGFloat = 54) {
        self.kind = kind
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(ColorTokens.surfacePrimary.opacity(0.78))
                .frame(width: size, height: size)

            Image(systemName: icon)
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(iconStyle)
        }
        .allowsHitTesting(false)
    }

    private var icon: String {
        switch kind {
        case .locked:
            return "lock.fill"
        case .completed:
            return "checkmark.seal.fill"
        }
    }

    private var iconStyle: AnyShapeStyle {
        switch kind {
        case .locked:
            return AnyShapeStyle(ColorTokens.textPrimary)
        case .completed:
            return AnyShapeStyle(ThemeGradients.brushWarm)
        }
    }
}
