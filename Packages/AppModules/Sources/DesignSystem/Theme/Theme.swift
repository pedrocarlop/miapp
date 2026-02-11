/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Theme/Theme.swift
 - Rol principal: Compone el tema visual final a partir de tokens y lo expone a la UI.
 - Flujo simplificado: Entrada: tokens/base theme. | Proceso: combinar y derivar valores visuales. | Salida: tema completo consumible por vistas.
 - Tipos clave en este archivo: Theme
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

public struct Theme {
    public let backgroundPrimary: Color
    public let surfacePrimary: Color
    public let surfaceSecondary: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let accentPrimary: Color

    public init(
        backgroundPrimary: Color,
        surfacePrimary: Color,
        surfaceSecondary: Color,
        textPrimary: Color,
        textSecondary: Color,
        accentPrimary: Color
    ) {
        self.backgroundPrimary = backgroundPrimary
        self.surfacePrimary = surfacePrimary
        self.surfaceSecondary = surfaceSecondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accentPrimary = accentPrimary
    }

    public static let `default` = Theme(
        backgroundPrimary: ThemeColors.backgroundPaper,
        surfacePrimary: ThemeColors.surfacePaper,
        surfaceSecondary: ThemeColors.surfacePaperMuted,
        textPrimary: ThemeColors.inkPrimary,
        textSecondary: ThemeColors.inkSecondary,
        accentPrimary: ThemeColors.accentCoral
    )
}
