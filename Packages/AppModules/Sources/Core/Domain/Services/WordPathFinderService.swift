import Foundation

public enum WordPathFinderService {
    private static let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]

    public static func bestPath(
        for word: String,
        grid: Grid,
        prioritizing solvedPositions: Set<GridPosition> = []
    ) -> [GridPosition]? {
        let candidates = candidatePaths(for: word, grid: grid)
        guard !candidates.isEmpty else { return nil }
        return candidates.max { pathScore($0, solvedPositions: solvedPositions) < pathScore($1, solvedPositions: solvedPositions) }
    }

    public static func candidatePaths(for word: String, grid: Grid) -> [[GridPosition]] {
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
                        collected.append(grid.letters[r][c].uppercased())
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
}
