/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Data/Repositories/LocalStreakRepository.swift
 - Rol principal: Capa de acceso a datos: guarda/lee informacion de almacenamiento local o remoto.
 - Flujo simplificado: Entrada: peticion de lectura/escritura. | Proceso: persistir o recuperar datos. | Salida: datos en formato de dominio.
 - Tipos clave en este archivo: LocalStreakRepository
 - Funciones clave en este archivo: load,refresh markCompleted,persist
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

public final class LocalStreakRepository: StreakRepository {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    public func load() -> Streak {
        let current = store.integer(forKey: WordSearchConfig.streakCurrentKey)
        let last = store.object(forKey: WordSearchConfig.streakLastCompletedKey) as? Int ?? -1
        return Streak(current: current, lastCompletedOffset: last)
    }

    public func refresh(todayKey: DayKey) -> Streak {
        var state = load()
        if state.lastCompletedOffset >= 0 && state.lastCompletedOffset < todayKey.offset - 1 {
            state.current = 0
            persist(state)
        }
        return state
    }

    public func markCompleted(dayKey: DayKey, todayKey: DayKey) -> Streak {
        var state = load()
        guard dayKey.offset == todayKey.offset else {
            return state
        }
        guard state.lastCompletedOffset != todayKey.offset else {
            return state
        }

        if state.lastCompletedOffset == todayKey.offset - 1 {
            state.current += 1
        } else {
            state.current = 1
        }
        state.lastCompletedOffset = todayKey.offset
        persist(state)
        return state
    }

    private func persist(_ streak: Streak) {
        store.set(streak.current, forKey: WordSearchConfig.streakCurrentKey)
        store.set(streak.lastCompletedOffset, forKey: WordSearchConfig.streakLastCompletedKey)
    }
}
