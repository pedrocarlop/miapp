/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Theme/ThemeTypography.swift
 - Rol principal: Compone el tema visual final a partir de tokens y lo expone a la UI.
 - Flujo simplificado: Entrada: tokens/base theme. | Proceso: combinar y derivar valores visuales. | Salida: tema completo consumible por vistas.
 - Tipos clave en este archivo: ThemeTypography
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

public enum ThemeTypography {
    public static let displayTitle = TypographyTokens.displayTitle
    public static let screenTitle = TypographyTokens.screenTitle
    public static let sectionTitle = TypographyTokens.sectionTitle
    public static let body = TypographyTokens.body
    public static let bodyStrong = TypographyTokens.bodyStrong
    public static let caption = TypographyTokens.caption
}
