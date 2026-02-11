/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Tokens/ZIndexTokens.swift
 - Rol principal: Define constantes visuales (colores, espacios, radios, tipografia, animaciones).
 - Flujo simplificado: Entrada: no suele tener entrada dinamica (constantes). | Proceso: exponer valores de diseno. | Salida: referencias consistentes para UI.
 - Tipos clave en este archivo: ZIndexTokens
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

public enum ZIndexTokens {
    public static let background: Double = 0
    public static let content: Double = 10
    public static let overlay: Double = 50
    public static let modal: Double = 100
}
