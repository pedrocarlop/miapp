/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Tokens/TypographyTokens.swift
 - Rol principal: Define constantes visuales (colores, espacios, radios, tipografia, animaciones).
 - Flujo simplificado: Entrada: no suele tener entrada dinamica (constantes). | Proceso: exponer valores de diseno. | Salida: referencias consistentes para UI.
 - Tipos clave en este archivo: TypographyTokens
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

public enum TypographyTokens {
    private enum FontName {
        static let instrumentSerif = "InstrumentSerif-Regular"
    }

    private static func serif(_ size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        // SwiftUI falls back to a system font if the custom face is unavailable.
        .custom(FontName.instrumentSerif, size: size, relativeTo: textStyle)
    }

    // MARK: - Semantic styles
    public static let displayTitle = serif(38, relativeTo: .largeTitle).weight(.bold)
    public static let screenTitle = serif(30, relativeTo: .title2).weight(.semibold)
    public static let sectionTitle = serif(24, relativeTo: .title3).weight(.semibold)
    public static let body = Font.system(.body, design: .default)
    public static let bodyStrong = Font.system(.body, design: .default).weight(.semibold)
    public static let callout = Font.system(.callout, design: .default)
    public static let footnote = Font.system(.footnote, design: .default)
    public static let caption = Font.system(.caption, design: .default)

    // MARK: - Legacy aliases
    public static let titleLarge = displayTitle
    public static let titleMedium = screenTitle
    public static let titleSmall = sectionTitle
    public static let wordChip = Font.system(.body, design: .rounded).weight(.semibold)
    public static let wordDescription = Font.system(.body, design: .default)

    public static func boardLetter(size: CGFloat) -> Font {
        Font.system(size: size, weight: .semibold, design: .rounded)
    }

    public static let monoBody = Font.system(.body, design: .default).weight(.semibold)
}
