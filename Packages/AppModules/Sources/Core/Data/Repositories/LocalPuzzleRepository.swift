/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Data/Repositories/LocalPuzzleRepository.swift
 - Rol principal: Capa de acceso a datos: guarda/lee informacion de almacenamiento local o remoto.
 - Flujo simplificado: Entrada: peticion de lectura/escritura. | Proceso: persistir o recuperar datos. | Salida: datos en formato de dominio.
 - Tipos clave en este archivo: LocalPuzzleRepository
 - Funciones clave en este archivo: installationDate,dayOffset date,puzzle normalizedPuzzleIndex
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

public final class LocalPuzzleRepository: PuzzleRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public func installationDate() -> Date {
        let calendar = Calendar.current
        let fallback = calendar.startOfDay(for: Date())

        if let stored = store.object(forKey: WordSearchConfig.installDateKey) as? Date {
            return calendar.startOfDay(for: stored)
        }

        store.set(fallback, forKey: WordSearchConfig.installDateKey)
        return fallback
    }

    public func dayOffset(from start: Date, to target: Date) -> DayKey {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let targetDay = calendar.startOfDay(for: target)
        let offset = max(calendar.dateComponents([.day], from: startDay, to: targetDay).day ?? 0, 0)
        return DayKey(offset: offset)
    }

    public func date(from start: Date, dayKey: DayKey) -> Date {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        return calendar.date(byAdding: .day, value: dayKey.offset, to: startDay) ?? startDay
    }

    public func puzzle(for dayKey: DayKey, gridSize: Int) -> Puzzle {
        PuzzleFactory.puzzle(for: dayKey, gridSize: gridSize)
    }

    public func normalizedPuzzleIndex(_ index: Int) -> Int {
        PuzzleFactory.normalizedPuzzleIndex(index)
    }
}
