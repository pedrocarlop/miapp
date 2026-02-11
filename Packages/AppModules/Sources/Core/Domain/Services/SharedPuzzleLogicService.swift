/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Domain/Services/SharedPuzzleLogicService.swift
 - Rol principal: Implementa reglas de negocio puras del dominio (logica principal del producto).
 - Flujo simplificado: Entrada: entidades/parametros de negocio. | Proceso: aplicar reglas y restricciones del dominio. | Salida: decision o resultado de negocio.
 - Tipos clave en este archivo: SharedPuzzleLogicService
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

public enum SharedPuzzleLogicService {
    private static let feedbackDuration: TimeInterval = 0.4
    private static let hintDuration: TimeInterval? = nil

    public static func applyTap(state: SharedPuzzleState, row: Int, col: Int, now: Date) -> SharedPuzzleState {
        var next = resolveExpiredFeedback(state: state, now: now)

        guard row >= 0, col >= 0, row < next.grid.count, col < (next.grid.first?.count ?? 0) else {
            return next
        }

        if next.isCompleted {
            return next
        }

        let tapped = GridPosition(row: row, col: col)
        next.isHelpVisible = false

        guard let anchor = next.anchor else {
            next.anchor = tapped
            next.feedback = nil
            next.pendingWord = nil
            next.pendingSolvedPositions.removeAll()
            return next
        }

        if anchor == tapped {
            next.anchor = nil
            next.feedback = nil
            next.pendingWord = nil
            next.pendingSolvedPositions.removeAll()
            return next
        }

        let grid = PuzzleGrid(letters: next.grid)
        let linePath = SelectionValidationService.path(from: anchor, to: tapped, grid: grid)
        if let linePath,
           let matchedWord = wordFromPath(grid: grid, allowedWords: next.words, path: linePath) {
            let normalizedWord = WordSearchNormalization.normalizedWord(matchedWord)
            next.foundWords.insert(normalizedWord)
            next.solvedPositions.formUnion(linePath)
            next.feedback = SelectionFeedback(
                kind: .correct,
                positions: linePath,
                expiresAt: now.addingTimeInterval(feedbackDuration)
            )
            next.pendingWord = nil
            next.pendingSolvedPositions.removeAll()
            applyNextHint(into: &next, now: now)
        } else {
            let preview = linePath ?? [anchor, tapped]
            next.feedback = SelectionFeedback(
                kind: .incorrect,
                positions: preview,
                expiresAt: now.addingTimeInterval(feedbackDuration)
            )
            next.pendingWord = nil
            next.pendingSolvedPositions.removeAll()
        }

        next.anchor = nil
        return next
    }

    public static func resolveExpiredFeedback(state: SharedPuzzleState, now: Date) -> SharedPuzzleState {
        var next = state

        if let feedback = state.feedback, now >= feedback.expiresAt {
            if feedback.kind == .correct,
               let pendingWord = next.pendingWord.map(WordSearchNormalization.normalizedWord) {
                next.foundWords.insert(pendingWord)
                next.solvedPositions.formUnion(next.pendingSolvedPositions)
            }
            next.feedback = nil
            next.pendingWord = nil
            next.pendingSolvedPositions.removeAll()
        }

        if let hintExpiry = state.nextHintExpiresAt, now >= hintExpiry {
            next.nextHintWord = nil
            next.nextHintExpiresAt = nil
        }

        return next
    }

    public static func wordFromPath(grid: PuzzleGrid, allowedWords: [String], path: [GridPosition]) -> String? {
        guard path.count >= 2 else { return nil }
        guard let candidate = grid.word(at: path) else { return nil }

        let normalized = WordSearchNormalization.normalizedWord(candidate)
        let reversed = String(normalized.reversed())
        let allowed = Set(allowedWords.map(WordSearchNormalization.normalizedWord))

        if allowed.contains(normalized) {
            return normalized
        }
        if allowed.contains(reversed) {
            return reversed
        }
        return nil
    }

    private static func applyNextHint(into state: inout SharedPuzzleState, now: Date) {
        guard !state.isCompleted else {
            state.nextHintWord = nil
            state.nextHintExpiresAt = nil
            return
        }

        if let nextWord = nextUnfoundWord(in: state) {
            state.nextHintWord = nextWord
            if let hintDuration {
                state.nextHintExpiresAt = now.addingTimeInterval(hintDuration)
            } else {
                state.nextHintExpiresAt = nil
            }
        } else {
            state.nextHintWord = nil
            state.nextHintExpiresAt = nil
        }
    }

    private static func nextUnfoundWord(in state: SharedPuzzleState) -> String? {
        let found = Set(state.foundWords.map(WordSearchNormalization.normalizedWord))
        for word in state.words {
            let normalized = WordSearchNormalization.normalizedWord(word)
            if !found.contains(normalized) {
                return normalized
            }
        }
        return nil
    }
}
