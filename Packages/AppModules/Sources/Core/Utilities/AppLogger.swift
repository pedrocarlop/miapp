/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Utilities/AppLogger.swift
 - Rol principal: Funciones auxiliares compartidas para evitar duplicar logica transversal.
 - Flujo simplificado: Entrada: parametros concretos. | Proceso: calculo helper acotado. | Salida: valor util para otras capas.
 - Tipos clave en este archivo: AppLogLevel,AppLogCategory AppLogger
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

public enum AppLogLevel: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case error = "ERROR"
}

public enum AppLogCategory: String, Sendable {
    case persistence
    case migration
    case state
    case ui
    case general
}

public enum AppLogger {
    public static func debug(
        _ message: String,
        category: AppLogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #fileID,
        line: UInt = #line
    ) {
        log(
            level: .debug,
            message: message,
            category: category,
            metadata: metadata,
            file: file,
            line: line
        )
    }

    public static func info(
        _ message: String,
        category: AppLogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #fileID,
        line: UInt = #line
    ) {
        log(
            level: .info,
            message: message,
            category: category,
            metadata: metadata,
            file: file,
            line: line
        )
    }

    public static func error(
        _ message: String,
        category: AppLogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #fileID,
        line: UInt = #line
    ) {
        log(
            level: .error,
            message: message,
            category: category,
            metadata: metadata,
            file: file,
            line: line
        )
    }

    private static func log(
        level: AppLogLevel,
        message: String,
        category: AppLogCategory,
        metadata: [String: String],
        file: String,
        line: UInt
    ) {
        let metadataText = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        let context = "[\(category.rawValue)] \(file):\(line)"
        let finalMessage: String
        if metadataText.isEmpty {
            finalMessage = "[\(level.rawValue)] \(context) - \(message)"
        } else {
            finalMessage = "[\(level.rawValue)] \(context) - \(message) {\(metadataText)}"
        }

#if DEBUG
        print(finalMessage)
        if level == .error {
            assertionFailure(finalMessage)
        }
#else
        if level == .error {
            NSLog("%@", finalMessage)
        }
#endif
    }
}
