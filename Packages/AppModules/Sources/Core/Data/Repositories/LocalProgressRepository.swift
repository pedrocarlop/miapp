/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Data/Repositories/LocalProgressRepository.swift
 - Rol principal: Capa de acceso a datos: guarda/lee informacion de almacenamiento local o remoto.
 - Flujo simplificado: Entrada: peticion de lectura/escritura. | Proceso: persistir o recuperar datos. | Salida: datos en formato de dominio.
 - Tipos clave en este archivo: LocalProgressRepository
 - Funciones clave en este archivo: loadRecords,loadRecord save,reset markCompleted,completedDayOffsets
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

public final class LocalProgressRepository: ProgressRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public static func key(for dayOffset: Int, gridSize: Int) -> String {
        AppProgressRecordKey.make(dayOffset: dayOffset, gridSize: gridSize)
    }

    public func loadRecords() -> [String: AppProgressRecord] {
        guard let data = store.data(forKey: WordSearchConfig.appProgressKey) else {
            return [:]
        }

        guard let decoded = try? JSONDecoder().decode([String: AppProgressRecordDTO].self, from: data) else {
            AppLogger.error(
                "Failed to decode progress records",
                category: .persistence,
                metadata: [
                    "key": WordSearchConfig.appProgressKey,
                    "bytes": "\(data.count)"
                ]
            )
            return [:]
        }

        return decoded.mapValues(StateMappers.toDomain)
    }

    public func loadRecord(dayKey: DayKey, preferredGridSize: Int) -> AppProgressRecord? {
        let records = loadRecords()
        return ProgressRecordResolver.resolve(
            dayKey: dayKey,
            preferredGridSize: preferredGridSize,
            records: records
        )
    }

    public func save(_ record: AppProgressRecord) {
        var records = loadRecords()
        records[Self.key(for: record.dayOffset, gridSize: record.gridSize)] = record
        persist(records)
    }

    public func reset(dayKey: DayKey, gridSize: Int) {
        var records = loadRecords()
        records.removeValue(forKey: Self.key(for: dayKey.offset, gridSize: gridSize))
        persist(records)
    }

    public func markCompleted(dayKey: DayKey) {
        var current = completedDayOffsets()
        current.insert(dayKey.offset)
        store.set(Array(current).sorted(), forKey: WordSearchConfig.completedOffsetsKey)
    }

    public func completedDayOffsets() -> Set<Int> {
        let values = store.array(forKey: WordSearchConfig.completedOffsetsKey) as? [Int] ?? []
        return Set(values)
    }

    private func persist(_ records: [String: AppProgressRecord]) {
        let dtoMap = records.mapValues(StateMappers.toDTO)
        guard let data = try? JSONEncoder().encode(dtoMap) else {
            AppLogger.error(
                "Failed to encode progress records",
                category: .persistence,
                metadata: [
                    "key": WordSearchConfig.appProgressKey,
                    "recordCount": "\(records.count)"
                ]
            )
            return
        }
        store.set(data, forKey: WordSearchConfig.appProgressKey)
    }
}
