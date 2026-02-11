/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Theme/ThemeSpacing.swift
 - Rol principal: Compone el tema visual final a partir de tokens y lo expone a la UI.
 - Flujo simplificado: Entrada: tokens/base theme. | Proceso: combinar y derivar valores visuales. | Salida: tema completo consumible por vistas.
 - Tipos clave en este archivo: ThemeSpacing
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

import CoreGraphics

public enum ThemeSpacing {
    public static let xxs = SpacingTokens.xxs
    public static let xs = SpacingTokens.xs
    public static let sm = SpacingTokens.sm
    public static let md = SpacingTokens.md
    public static let lg = SpacingTokens.lg
    public static let xl = SpacingTokens.xl
}
