/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Domain/Services/WordHintsService.swift
 - Rol principal: Implementa reglas de negocio puras del dominio (logica principal del producto).
 - Flujo simplificado: Entrada: entidades/parametros de negocio. | Proceso: aplicar reglas y restricciones del dominio. | Salida: decision o resultado de negocio.
 - Tipos clave en este archivo: WordHintsService
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

import Foundation

public enum WordHintsService {
    public static func displayText(for word: String, mode: WordHintMode) -> String {
        switch mode {
        case .word:
            return WordSearchNormalization.normalizedWord(word)
        case .definition:
            return definition(for: word) ?? missingDefinition
        }
    }

    public static func definition(for word: String) -> String? {
        let normalized = WordSearchNormalization.normalizedWord(word)
        let canonical = PuzzleFactory.canonicalWord(for: normalized) ?? normalized
        let key = "word_hint.\(canonical)"
        let value = localized(key, default: key)
        return value == key ? nil : value
    }

    private static var missingDefinition: String {
        localized("word_hint.missing", default: "Sin definición")
    }

    private static func localized(_ key: String, default value: String) -> String {
        AppLocalization.localized(key, default: value, bundle: .module)
    }
}
