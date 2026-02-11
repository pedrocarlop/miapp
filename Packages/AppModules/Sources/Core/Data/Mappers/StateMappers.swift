/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Data/Mappers/StateMappers.swift
 - Rol principal: Convierte datos entre formatos (DTO <-> modelo de dominio/UI).
 - Flujo simplificado: Entrada: objeto origen. | Proceso: mapear campos y normalizar formatos. | Salida: objeto destino equivalente.
 - Tipos clave en este archivo: StateMappers
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

public enum StateMappers {
    public static func toDomain(_ dto: SharedPuzzleStateDTO) -> SharedPuzzleState {
        SharedPuzzleState(
            grid: dto.grid,
            words: dto.words,
            gridSize: dto.gridSize,
            anchor: dto.anchor.map(toDomain),
            foundWords: dto.foundWords,
            solvedPositions: Set(dto.solvedPositions.map(toDomain)),
            puzzleIndex: dto.puzzleIndex,
            isHelpVisible: dto.isHelpVisible,
            feedback: dto.feedback.map(toDomain),
            pendingWord: dto.pendingWord,
            pendingSolvedPositions: Set(dto.pendingSolvedPositions.map(toDomain)),
            nextHintWord: dto.nextHintWord,
            nextHintExpiresAt: dto.nextHintExpiresAt
        )
    }

    public static func toDTO(_ state: SharedPuzzleState) -> SharedPuzzleStateDTO {
        SharedPuzzleStateDTO(
            grid: state.grid,
            words: state.words,
            gridSize: state.gridSize,
            anchor: state.anchor.map(toDTO),
            foundWords: state.foundWords,
            solvedPositions: Set(state.solvedPositions.map(toDTO)),
            puzzleIndex: state.puzzleIndex,
            isHelpVisible: state.isHelpVisible,
            feedback: state.feedback.map(toDTO),
            pendingWord: state.pendingWord,
            pendingSolvedPositions: Set(state.pendingSolvedPositions.map(toDTO)),
            nextHintWord: state.nextHintWord,
            nextHintExpiresAt: state.nextHintExpiresAt
        )
    }

    public static func toDomain(_ dto: AppProgressRecordDTO) -> AppProgressRecord {
        AppProgressRecord(
            dayOffset: dto.dayOffset,
            gridSize: dto.gridSize,
            foundWords: dto.foundWords,
            solvedPositions: dto.solvedPositions.map(toDomain),
            startedAt: dto.startedAt,
            endedAt: dto.endedAt
        )
    }

    public static func toDTO(_ model: AppProgressRecord) -> AppProgressRecordDTO {
        AppProgressRecordDTO(
            dayOffset: model.dayOffset,
            gridSize: model.gridSize,
            foundWords: model.foundWords,
            solvedPositions: model.solvedPositions.map(toDTO),
            startedAt: model.startedAt,
            endedAt: model.endedAt
        )
    }

    public static func toDomain(_ dto: SharedPositionDTO) -> GridPosition {
        GridPosition(row: dto.r, col: dto.c)
    }

    public static func toDTO(_ position: GridPosition) -> SharedPositionDTO {
        SharedPositionDTO(r: position.row, c: position.col)
    }

    public static func toDomain(_ dto: SharedFeedbackDTO) -> SelectionFeedback {
        SelectionFeedback(
            kind: dto.kind == .correct ? .correct : .incorrect,
            positions: dto.positions.map(toDomain),
            expiresAt: dto.expiresAt
        )
    }

    public static func toDTO(_ feedback: SelectionFeedback) -> SharedFeedbackDTO {
        SharedFeedbackDTO(
            kind: feedback.kind == .correct ? .correct : .incorrect,
            positions: feedback.positions.map(toDTO),
            expiresAt: feedback.expiresAt
        )
    }

    public static func toDomain(_ dto: AppProgressPositionDTO) -> GridPosition {
        GridPosition(row: dto.row, col: dto.col)
    }

    public static func toDTO(_ position: GridPosition) -> AppProgressPositionDTO {
        AppProgressPositionDTO(row: position.row, col: position.col)
    }
}
