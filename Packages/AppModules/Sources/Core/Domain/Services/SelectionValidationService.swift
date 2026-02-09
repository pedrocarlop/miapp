import Foundation

public struct SelectionValidationResult: Hashable, Sendable {
    public let matchedWord: String?
    public let normalizedPath: [GridPosition]

    public init(matchedWord: String?, normalizedPath: [GridPosition]) {
        self.matchedWord = matchedWord
        self.normalizedPath = normalizedPath
    }

    public var isValidWord: Bool {
        matchedWord != nil
    }
}

public enum SelectionValidationService {
    public static func snappedDirection(from start: GridPosition, to end: GridPosition) -> (Int, Int) {
        let drRaw = end.row - start.row
        let dcRaw = end.col - start.col
        guard drRaw != 0 || dcRaw != 0 else { return (0, 0) }

        let angle = atan2(Double(drRaw), Double(dcRaw))
        let octant = Int(round(angle / (.pi / 4)))
        let index = (octant + 8) % 8
        let directions: [(Int, Int)] = [
            (0, 1), (1, 1), (1, 0), (1, -1),
            (0, -1), (-1, -1), (-1, 0), (-1, 1)
        ]
        return directions[index]
    }

    public static func selectionPath(
        from start: GridPosition,
        to end: GridPosition,
        direction: (Int, Int),
        grid: Grid
    ) -> [GridPosition] {
        let drRaw = end.row - start.row
        let dcRaw = end.col - start.col
        let steps = max(abs(drRaw), abs(dcRaw))

        guard steps >= 0 else { return [start] }

        return (0...steps).compactMap { step in
            let row = start.row + direction.0 * step
            let col = start.col + direction.1 * step
            let position = GridPosition(row: row, col: col)
            return grid.contains(position) ? position : nil
        }
    }

    public static func path(from start: GridPosition, to end: GridPosition, grid: Grid) -> [GridPosition]? {
        let dr = end.row - start.row
        let dc = end.col - start.col
        let absDr = abs(dr)
        let absDc = abs(dc)

        if !(dr == 0 || dc == 0 || absDr == absDc) {
            return nil
        }

        let stepR = dr == 0 ? 0 : dr / absDr
        let stepC = dc == 0 ? 0 : dc / absDc
        let steps = max(absDr, absDc)
        var result: [GridPosition] = []
        result.reserveCapacity(steps + 1)

        for index in 0...steps {
            let position = GridPosition(row: start.row + index * stepR, col: start.col + index * stepC)
            guard grid.contains(position) else { return nil }
            result.append(position)
        }

        return result
    }

    public static func validate(
        selection: Selection,
        puzzle: Puzzle,
        alreadyFoundWords: Set<String>
    ) -> SelectionValidationResult {
        let normalizedFound = Set(alreadyFoundWords.map(WordSearchNormalization.normalizedWord))
        let positions = selection.positions

        guard positions.count >= 2 else {
            return SelectionValidationResult(matchedWord: nil, normalizedPath: positions)
        }

        guard let candidate = puzzle.grid.word(at: positions) else {
            return SelectionValidationResult(matchedWord: nil, normalizedPath: positions)
        }

        let normalizedCandidate = WordSearchNormalization.normalizedWord(candidate)
        let reversed = String(normalizedCandidate.reversed())
        let allowed = puzzle.wordSet

        if allowed.contains(normalizedCandidate), !normalizedFound.contains(normalizedCandidate) {
            return SelectionValidationResult(matchedWord: normalizedCandidate, normalizedPath: positions)
        }

        if allowed.contains(reversed), !normalizedFound.contains(reversed) {
            return SelectionValidationResult(matchedWord: reversed, normalizedPath: positions)
        }

        return SelectionValidationResult(matchedWord: nil, normalizedPath: positions)
    }
}
