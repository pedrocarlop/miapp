/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Data/Persistence/KeyValueStore.swift
 - Rol principal: Soporte general de arquitectura: tipos, configuracion o pegamento entre modulos.
 - Flujo simplificado: Entrada: contexto de modulo. | Proceso: ejecutar responsabilidad local del archivo. | Salida: tipo/valor usado por otras piezas.
 - Tipos clave en este archivo: KeyValueStore,UserDefaultsStore InMemoryKeyValueStore
 - Funciones clave en este archivo: data,object array,string integer,double
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

public protocol KeyValueStore: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func object(forKey defaultName: String) -> Any?
    func array(forKey defaultName: String) -> [Any]?
    func string(forKey defaultName: String) -> String?
    func integer(forKey defaultName: String) -> Int
    func double(forKey defaultName: String) -> Double
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

public final class UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    public init?(suiteName: String = WordSearchConfig.suiteName) {
        guard Self.isAccessibleSuite(suiteName) else {
            AppLogger.error(
                "App Group suite is not accessible",
                category: .persistence,
                metadata: ["suiteName": suiteName]
            )
            return nil
        }
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            AppLogger.error(
                "Unable to initialize UserDefaults suite",
                category: .persistence,
                metadata: ["suiteName": suiteName]
            )
            return nil
        }
        self.defaults = defaults
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func data(forKey defaultName: String) -> Data? {
        defaults.data(forKey: defaultName)
    }

    public func object(forKey defaultName: String) -> Any? {
        defaults.object(forKey: defaultName)
    }

    public func array(forKey defaultName: String) -> [Any]? {
        defaults.array(forKey: defaultName)
    }

    public func string(forKey defaultName: String) -> String? {
        defaults.string(forKey: defaultName)
    }

    public func integer(forKey defaultName: String) -> Int {
        defaults.integer(forKey: defaultName)
    }

    public func double(forKey defaultName: String) -> Double {
        defaults.double(forKey: defaultName)
    }

    public func set(_ value: Any?, forKey defaultName: String) {
        defaults.set(value, forKey: defaultName)
    }

    public func removeObject(forKey defaultName: String) {
        defaults.removeObject(forKey: defaultName)
    }

    private static func isAccessibleSuite(_ suiteName: String) -> Bool {
        guard suiteName.hasPrefix("group.") else {
            return true
        }

        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        ) != nil
    }
}

public final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Any] = [:]

    public init() {}

    public func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    public func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    public func array(forKey defaultName: String) -> [Any]? {
        storage[defaultName] as? [Any]
    }

    public func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }

    public func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    public func double(forKey defaultName: String) -> Double {
        storage[defaultName] as? Double ?? 0
    }

    public func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    public func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
}
