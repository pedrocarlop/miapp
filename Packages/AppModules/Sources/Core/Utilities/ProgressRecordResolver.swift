/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Utilities/ProgressRecordResolver.swift
 - Rol principal: Funciones auxiliares compartidas para evitar duplicar logica transversal.
 - Flujo simplificado: Entrada: parametros concretos. | Proceso: calculo helper acotado. | Salida: valor util para otras capas.
 - Tipos clave en este archivo: ProgressRecordResolver
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

public enum ProgressRecordResolver {
    public static func resolve(
        dayKey: DayKey,
        preferredGridSize: Int,
        records: [String: AppProgressRecord]
    ) -> AppProgressRecord? {
        resolve(
            dayOffset: dayKey.offset,
            preferredGridSize: preferredGridSize,
            records: records
        )
    }

    public static func resolve(
        dayOffset: Int,
        preferredGridSize: Int,
        records: [String: AppProgressRecord]
    ) -> AppProgressRecord? {
        assert(preferredGridSize > 0, "Preferred grid size must be positive.")
        let preferredKey = AppProgressRecordKey.make(
            dayOffset: dayOffset,
            gridSize: preferredGridSize
        )
        if let preferred = records[preferredKey] {
            return preferred
        }

        let candidates = records.values.filter { $0.dayOffset == dayOffset }
        return candidates.max(by: isBetter(lhs:rhs:))
    }

    private static func isBetter(lhs: AppProgressRecord, rhs: AppProgressRecord) -> Bool {
        let lhsActivity = max(lhs.startedAt ?? -1, lhs.endedAt ?? -1)
        let rhsActivity = max(rhs.startedAt ?? -1, rhs.endedAt ?? -1)
        if lhsActivity != rhsActivity {
            return lhsActivity < rhsActivity
        }

        let lhsEnded = lhs.endedAt ?? -1
        let rhsEnded = rhs.endedAt ?? -1
        if lhsEnded != rhsEnded {
            return lhsEnded < rhsEnded
        }

        return lhs.gridSize < rhs.gridSize
    }
}
