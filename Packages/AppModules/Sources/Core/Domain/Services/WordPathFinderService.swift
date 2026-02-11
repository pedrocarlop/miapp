/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Domain/Services/WordPathFinderService.swift
 - Rol principal: Implementa reglas de negocio puras del dominio (logica principal del producto).
 - Flujo simplificado: Entrada: entidades/parametros de negocio. | Proceso: aplicar reglas y restricciones del dominio. | Salida: decision o resultado de negocio.
 - Tipos clave en este archivo: WordPathFinderService
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

public enum WordPathFinderService {
    private struct CacheKey: Hashable {
        let word: String
        let grid: String
        let solved: String
    }

    private static let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]
    private static let cacheLock = NSLock()
    private static let maxCacheEntries = 2_000
    private static var pathCache: [CacheKey: [GridPosition]] = [:]
    private static var missingCache: Set<CacheKey> = []

    public static func bestPath(
        for word: String,
        grid: PuzzleGrid,
        prioritizing solvedPositions: Set<GridPosition> = []
    ) -> [GridPosition]? {
        let normalizedWord = WordSearchNormalization.normalizedWord(word)
        guard !normalizedWord.isEmpty else { return nil }

        let key = cacheKey(
            normalizedWord: normalizedWord,
            grid: grid,
            solvedPositions: solvedPositions
        )
        if let cached = cachedPath(for: key) {
            return cached
        }
        if isMissingPath(for: key) {
            return nil
        }

        let candidates = candidatePaths(for: normalizedWord, grid: grid)
        guard !candidates.isEmpty else {
            cacheMissingPath(for: key)
            return nil
        }
        guard let resolved = candidates.max(
            by: { pathScore($0, solvedPositions: solvedPositions) < pathScore($1, solvedPositions: solvedPositions) }
        ) else {
            cacheMissingPath(for: key)
            return nil
        }

        cachePath(resolved, for: key)
        return resolved
    }

    public static func candidatePaths(for word: String, grid: PuzzleGrid) -> [[GridPosition]] {
        let normalizedWord = WordSearchNormalization.normalizedWord(word)
        let letters = normalizedWord.map(String.init)
        let reversed = Array(letters.reversed())
        let rowCount = grid.rowCount
        let colCount = grid.columnCount

        guard !letters.isEmpty else { return [] }
        guard rowCount > 0, colCount > 0 else { return [] }

        var results: [[GridPosition]] = []

        for row in 0..<rowCount {
            for col in 0..<colCount {
                for (dr, dc) in directions {
                    var path: [GridPosition] = []
                    var collected: [String] = []
                    var isValid = true

                    for step in 0..<letters.count {
                        let r = row + step * dr
                        let c = col + step * dc
                        if r < 0 || c < 0 || r >= rowCount || c >= colCount {
                            isValid = false
                            break
                        }

                        let position = GridPosition(row: r, col: c)
                        path.append(position)
                        collected.append(grid.letters[r][c])
                    }

                    guard isValid else { continue }
                    if collected == letters || collected == reversed {
                        results.append(path)
                    }
                }
            }
        }

        return results
    }

    private static func pathScore(_ path: [GridPosition], solvedPositions: Set<GridPosition>) -> Int {
        path.reduce(0) { partial, position in
            partial + (solvedPositions.contains(position) ? 1 : 0)
        }
    }

    private static func cacheKey(
        normalizedWord: String,
        grid: PuzzleGrid,
        solvedPositions: Set<GridPosition>
    ) -> CacheKey {
        CacheKey(
            word: normalizedWord,
            grid: gridSignature(grid),
            solved: solvedSignature(solvedPositions)
        )
    }

    private static func gridSignature(_ grid: PuzzleGrid) -> String {
        grid.letters.map { $0.joined() }.joined(separator: "|")
    }

    private static func solvedSignature(_ solvedPositions: Set<GridPosition>) -> String {
        guard !solvedPositions.isEmpty else { return "-" }
        return solvedPositions
            .sorted { lhs, rhs in
                if lhs.row == rhs.row {
                    return lhs.col < rhs.col
                }
                return lhs.row < rhs.row
            }
            .map { "\($0.row),\($0.col)" }
            .joined(separator: ";")
    }

    private static func cachedPath(for key: CacheKey) -> [GridPosition]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return pathCache[key]
    }

    private static func isMissingPath(for key: CacheKey) -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return missingCache.contains(key)
    }

    private static func cachePath(_ path: [GridPosition], for key: CacheKey) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        trimCacheIfNeeded()
        pathCache[key] = path
        missingCache.remove(key)
    }

    private static func cacheMissingPath(for key: CacheKey) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        trimCacheIfNeeded()
        missingCache.insert(key)
        pathCache.removeValue(forKey: key)
    }

    private static func trimCacheIfNeeded() {
        guard pathCache.count + missingCache.count >= maxCacheEntries else { return }
        pathCache.removeAll(keepingCapacity: true)
        missingCache.removeAll(keepingCapacity: true)
    }
}
