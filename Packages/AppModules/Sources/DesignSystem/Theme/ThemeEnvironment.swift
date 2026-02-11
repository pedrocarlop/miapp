/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/DesignSystem/Theme/ThemeEnvironment.swift
 - Rol principal: Compone el tema visual final a partir de tokens y lo expone a la UI.
 - Flujo simplificado: Entrada: tokens/base theme. | Proceso: combinar y derivar valores visuales. | Salida: tema completo consumible por vistas.
 - Tipos clave en este archivo: ThemeKey
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

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .default
}

public extension EnvironmentValues {
    var dsTheme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
