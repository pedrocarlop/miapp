/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Theme/ThemeColors.swift
 - Rol principal: Compone el tema visual final a partir de tokens y lo expone a la UI.
 - Flujo simplificado: Entrada: tokens/base theme. | Proceso: combinar y derivar valores visuales. | Salida: tema completo consumible por vistas.
 - Tipos clave en este archivo: ThemeColors
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

public enum ThemeColors {
    public static let backgroundPaper = ColorTokens.backgroundPaper
    public static let surfacePaper = ColorTokens.surfacePaper
    public static let surfacePaperMuted = ColorTokens.surfacePaperMuted
    public static let surfacePaperGrid = ColorTokens.surfacePaperGrid

    public static let inkPrimary = ColorTokens.inkPrimary
    public static let inkSecondary = ColorTokens.inkSecondary
    public static let gridLine = ColorTokens.gridLine
    public static let borderSoft = ColorTokens.borderSoft

    public static let accentCoral = ColorTokens.accentCoral
    public static let accentAmber = ColorTokens.accentAmber
    public static let accentCoralStrong = ColorTokens.accentCoralStrong
    public static let accentAmberStrong = ColorTokens.accentAmberStrong

    public static let success = ColorTokens.success
    public static let warning = ColorTokens.warning
    public static let error = ColorTokens.error
    public static let info = ColorTokens.info
}
