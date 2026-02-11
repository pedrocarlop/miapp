/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Domain/RepositoryProtocols/Repositories.swift
 - Rol principal: Capa de acceso a datos: guarda/lee informacion de almacenamiento local o remoto.
 - Flujo simplificado: Entrada: peticion de lectura/escritura. | Proceso: persistir o recuperar datos. | Salida: datos en formato de dominio.
 - Tipos clave en este archivo: PuzzleRepository,ProgressRepository StreakRepository,SettingsRepository
 - Funciones clave en este archivo: installationDate,dayOffset date,puzzle normalizedPuzzleIndex,loadRecords
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

public protocol PuzzleRepository {
    func installationDate() -> Date
    func dayOffset(from start: Date, to target: Date) -> DayKey
    func date(from start: Date, dayKey: DayKey) -> Date
    func puzzle(for dayKey: DayKey, gridSize: Int) -> Puzzle
    func normalizedPuzzleIndex(_ index: Int) -> Int
}

public protocol ProgressRepository {
    func loadRecords() -> [String: AppProgressRecord]
    func loadRecord(dayKey: DayKey, preferredGridSize: Int) -> AppProgressRecord?
    func save(_ record: AppProgressRecord)
    func reset(dayKey: DayKey, gridSize: Int)
    func markCompleted(dayKey: DayKey)
    func completedDayOffsets() -> Set<Int>
}

public protocol StreakRepository {
    func load() -> Streak
    func refresh(todayKey: DayKey) -> Streak
    func markCompleted(dayKey: DayKey, todayKey: DayKey) -> Streak
}

public protocol SettingsRepository {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

public protocol HintRepository {
    func state(todayKey: DayKey) -> HintState
    func spendHint(todayKey: DayKey) -> Bool
    func rewardCompletion(dayKey: DayKey, todayKey: DayKey) -> Bool
    func wasRewarded(todayKey: DayKey) -> Bool
}

public protocol SharedPuzzleRepository {
    func loadState(now: Date, preferredGridSize: Int) -> SharedPuzzleState
    func saveState(_ state: SharedPuzzleState)
    func clearProgress(puzzleIndex: Int, preferredGridSize: Int)
    func updateProgress(
        puzzleIndex: Int,
        gridSize: Int,
        foundWords: Set<String>,
        solvedPositions: Set<GridPosition>
    )
    func currentRotationBoundary(for now: Date) -> Date
}
