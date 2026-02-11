/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Utilities/AppLocalization.swift
 - Rol principal: Funciones auxiliares compartidas para evitar duplicar logica transversal.
 - Flujo simplificado: Entrada: parametros concretos. | Proceso: calculo helper acotado. | Salida: valor util para otras capas.
 - Tipos clave en este archivo: AppLocalization
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

public enum AppLocalization {
    private static let lock = NSLock()
    private static var cachedLanguage: AppLanguage?

    private static func suiteDefaults() -> UserDefaults? {
        UserDefaults(suiteName: WordSearchConfig.suiteName)
    }

    private static func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private static func setCachedLanguage(_ language: AppLanguage?) {
        withLock {
            cachedLanguage = language
        }
    }

    public static var currentLanguage: AppLanguage {
        if let cached = withLock({ cachedLanguage }) {
            return cached
        }

        let suiteRawValue = suiteDefaults()?.string(forKey: WordSearchConfig.appLanguageKey)
        if let suiteRawValue,
           let language = AppLanguage(rawValue: suiteRawValue) {
            setCachedLanguage(language)
            return language
        }

        let standardRawValue = UserDefaults.standard.string(forKey: WordSearchConfig.appLanguageKey)
        if let standardRawValue,
           let language = AppLanguage(rawValue: standardRawValue) {
            setCachedLanguage(language)
            return language
        }

        let resolved = AppLanguage.resolved()
        setCachedLanguage(resolved)
        return resolved
    }

    public static func setCurrentLanguage(_ language: AppLanguage) {
        setCachedLanguage(language)
        suiteDefaults()?.set(language.rawValue, forKey: WordSearchConfig.appLanguageKey)
        UserDefaults.standard.set(language.rawValue, forKey: WordSearchConfig.appLanguageKey)
    }

    static func resetCachedLanguageForTesting() {
        setCachedLanguage(nil)
    }

    public static var currentLocale: Locale {
        currentLanguage.locale
    }

    public static func localized(
        _ key: String,
        default defaultValue: String,
        bundle: Bundle,
        table: String? = nil
    ) -> String {
        let value = String(
            localized: String.LocalizationValue(key),
            table: table,
            bundle: bundle,
            locale: currentLocale,
            comment: ""
        )

        return value == key ? defaultValue : value
    }
}
