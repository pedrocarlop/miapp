/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Tokens/ThemeGradients.swift
 - Rol principal: Define constantes visuales (colores, espacios, radios, tipografia, animaciones).
 - Flujo simplificado: Entrada: no suele tener entrada dinamica (constantes). | Proceso: exponer valores de diseno. | Salida: referencias consistentes para UI.
 - Tipos clave en este archivo: ThemeGradients
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

public enum ThemeGradients {
    public static let brushWarm = LinearGradient(
        colors: [ColorTokens.accentCoral, ColorTokens.accentAmber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let brushWarmStrong = LinearGradient(
        colors: [ColorTokens.accentCoralStrong, ColorTokens.accentAmberStrong],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let completionBrush = LinearGradient(
        colors: [
            ColorTokens.accentAmberStrong.opacity(0.95),
            ColorTokens.accentCoralStrong.opacity(0.92)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let paperBackground = LinearGradient(
        colors: [ColorTokens.backgroundPaper, ColorTokens.surfacePaperMuted],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let wordListTopFade = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .clear, location: 0.0),
            .init(color: .black.opacity(0.62), location: 0.48),
            .init(color: .black, location: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
