/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Tokens/RadiusTokens.swift
 - Rol principal: Define constantes visuales (colores, espacios, radios, tipografia, animaciones).
 - Flujo simplificado: Entrada: no suele tener entrada dinamica (constantes). | Proceso: exponer valores de diseno. | Salida: referencias consistentes para UI.
 - Tipos clave en este archivo: RadiusTokens
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

public enum RadiusTokens {
    public static let chipRadius: CGFloat = 20
    public static let buttonRadius: CGFloat = 22
    public static let cardRadius: CGFloat = 24
    public static let boardRadius: CGFloat = 26
    public static let overlayRadius: CGFloat = 26
    public static let infiniteRadius: CGFloat = 999

    // Legacy aliases
    public static let sm: CGFloat = chipRadius
    public static let md: CGFloat = buttonRadius
    public static let lg: CGFloat = cardRadius
    public static let xl: CGFloat = boardRadius
    public static let pill: CGFloat = infiniteRadius
}
