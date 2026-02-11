/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Components/Feedback/DSFeedbackBanner.swift
 - Rol principal: Componente reutilizable del sistema de diseno para construir pantallas.
 - Flujo simplificado: Entrada: props/estado visual. | Proceso: construir composicion reutilizable. | Salida: bloque de UI consistente.
 - Tipos clave en este archivo: DSFeedbackBanner
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

public struct DSFeedbackBanner: View {
    public enum Kind {
        case success
        case warning
        case error
    }

    private let title: String
    private let message: String?
    private let kind: Kind

    public init(title: String, message: String? = nil, kind: Kind) {
        self.title = title
        self.message = message
        self.kind = kind
    }

    public var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            Image(systemName: icon)
                .font(TypographyTokens.bodyStrong)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                Text(title)
                    .font(TypographyTokens.bodyStrong)
                    .foregroundStyle(ColorTokens.inkPrimary)
                if let message {
                    Text(message)
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ColorTokens.inkSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(SpacingTokens.sm)
        .background(ColorTokens.surfaceSecondary, in: RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RadiusTokens.buttonRadius, style: .continuous)
                .stroke(color.opacity(0.45), lineWidth: 1)
        )
    }

    private var color: Color {
        switch kind {
        case .success: return ColorTokens.success
        case .warning: return ColorTokens.warning
        case .error: return ColorTokens.error
        }
    }

    private var icon: String {
        switch kind {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}
