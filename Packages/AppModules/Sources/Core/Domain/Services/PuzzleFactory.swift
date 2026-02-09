import Foundation

public enum PuzzleFactory {
    private static let themes: [[String]] = [
        [
            "ARBOL", "TIERRA", "NUBE", "MAR", "SOL", "RIO", "FLOR", "LUNA", "MONTE", "VALLE",
            "BOSQUE", "RAMA", "ROCA", "PLAYA", "NIEVE", "VIENTO", "TRUENO", "FUEGO", "ARENA",
            "ISLA", "CIELO", "SELVA", "LLUVIA", "CAMINO", "MUSGO", "LAGO", "PRIMAVERA",
            "HORIZONTE", "ESTRELLA", "PLANETA"
        ],
        [
            "QUESO", "PAN", "MIEL", "LECHE", "UVA", "PERA", "CAFE", "TOMATE", "ACEITE", "SAL",
            "PASTA", "ARROZ", "PAPAYA", "MANGO", "BANANA", "NARANJA", "CEREZA", "SOPA",
            "TORTILLA", "GALLETA", "CHOCOLATE", "YOGUR", "MANZANA", "AVENA", "ENSALADA",
            "PIMIENTO", "LIMON", "COCO", "ALMENDRA", "ALBAHACA"
        ],
        [
            "TREN", "BUS", "CARRO", "PUERTA", "PLAYA", "LIBRO", "CINE", "PUENTE", "CALLE",
            "METRO", "AVION", "BARRIO", "PLAZA", "PARQUE", "TORRE", "MUSEO", "MAPA", "RUTA",
            "BICICLETA", "TRAFICO", "SEMAFORO", "ESTACION", "AUTOPISTA", "TAXI", "MOTOR",
            "VIAJE", "MOCHILA", "PASEO", "CIUDAD", "CARTEL"
        ]
    ]

    public static func normalizedPuzzleIndex(_ offset: Int) -> Int {
        let count = max(themes.count, 1)
        let value = offset % count
        return value >= 0 ? value : value + count
    }

    public static func puzzle(for dayKey: DayKey, gridSize: Int) -> Puzzle {
        let normalizedIndex = normalizedPuzzleIndex(dayKey.offset)
        let clampedGridSize = clampGridSize(gridSize)
        let wordsPool = themes[normalizedIndex]
        let seed = stableSeed(dayOffset: dayKey.offset, gridSize: clampedGridSize)

        let selectedWords = selectWords(from: wordsPool, gridSize: clampedGridSize, seed: seed)
        let generated = WordSearchGenerator.generate(gridSize: clampedGridSize, words: selectedWords, seed: seed)

        return Puzzle(
            number: normalizedIndex + 1,
            dayKey: dayKey,
            grid: Grid(letters: generated.grid),
            words: generated.words.map(Word.init(text:))
        )
    }

    public static func clampGridSize(_ value: Int) -> Int {
        min(max(value, WordSearchConfig.minGridSize), WordSearchConfig.maxGridSize)
    }

    private static func stableSeed(dayOffset: Int, gridSize: Int) -> UInt64 {
        let a = UInt64(bitPattern: Int64(dayOffset))
        let b = UInt64(gridSize) << 32
        return (a &* 0x9E3779B185EBCA87) ^ b ^ 0xC0DEC0FFEE12345F
    }

    private static func targetWordCount(for gridSize: Int) -> Int {
        let size = clampGridSize(gridSize)
        return min(10, max(5, 5 + (size - WordSearchConfig.minGridSize)))
    }

    private static func selectWords(from pool: [String], gridSize: Int, seed: UInt64) -> [String] {
        var filtered = pool
            .map(WordSearchNormalization.normalizedWord)
            .filter { $0.count >= 3 && $0.count <= gridSize }

        if filtered.isEmpty {
            filtered = ["SOL", "MAR", "RIO", "LUNA", "FLOR", "ROCA"]
        }

        var rng = WordSearchGenerator.SeededGenerator(seed: seed ^ 0xA11CE5EED)
        for index in stride(from: filtered.count - 1, through: 1, by: -1) {
            let swapAt = rng.int(upperBound: index + 1)
            if swapAt != index {
                filtered.swapAt(index, swapAt)
            }
        }

        let targetCount = min(filtered.count, targetWordCount(for: gridSize))
        return Array(filtered.prefix(targetCount))
    }
}

public enum WordSearchGenerator {
    private static let directions: [(Int, Int)] = [
        (0, 1), (1, 0), (1, 1), (1, -1),
        (0, -1), (-1, 0), (-1, -1), (-1, 1)
    ]
    private static let alphabet: [String] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }

    public struct SeededGenerator {
        private var state: UInt64

        public init(seed: UInt64) {
            state = seed == 0 ? 0x1234ABCD5678EF90 : seed
        }

        public mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }

        public mutating func int(upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(next() % UInt64(upperBound))
        }
    }

    public struct GeneratedPuzzle {
        public let grid: [[String]]
        public let words: [String]

        public init(grid: [[String]], words: [String]) {
            self.grid = grid
            self.words = words
        }
    }

    public static func generate(gridSize: Int, words: [String], seed: UInt64) -> GeneratedPuzzle {
        let size = PuzzleFactory.clampGridSize(gridSize)
        let sortedWords = words
            .map(WordSearchNormalization.normalizedWord)
            .filter { !$0.isEmpty && $0.count <= size }
            .sorted { $0.count > $1.count }

        var fallback = makePuzzle(size: size, words: sortedWords, seed: seed, reduction: 0)
        if fallback.words.count >= 4 {
            return fallback
        }

        for reduction in [2, 4, 6] {
            let reduced = Array(sortedWords.prefix(max(4, sortedWords.count - reduction)))
            let attempt = makePuzzle(size: size, words: reduced, seed: seed, reduction: reduction)
            if attempt.words.count > fallback.words.count {
                fallback = attempt
            }
            if attempt.words.count >= max(4, reduced.count - 1) {
                return attempt
            }
        }

        return fallback
    }

    private static func makePuzzle(size: Int, words: [String], seed: UInt64, reduction: Int) -> GeneratedPuzzle {
        var rng = SeededGenerator(seed: seed ^ UInt64(reduction) ^ 0xFEEDBEEF15)
        var board = Array(repeating: Array(repeating: "", count: size), count: size)
        var placedWords: [String] = []

        for word in words {
            if place(word: word, on: &board, size: size, rng: &rng) {
                placedWords.append(word)
            }
        }

        for row in 0..<size {
            for col in 0..<size where board[row][col].isEmpty {
                board[row][col] = alphabet[rng.int(upperBound: alphabet.count)]
            }
        }

        return GeneratedPuzzle(grid: board, words: placedWords)
    }

    private static func place(word: String, on board: inout [[String]], size: Int, rng: inout SeededGenerator) -> Bool {
        let letters = word.map { String($0) }
        let count = letters.count
        guard count > 1 else { return false }

        for _ in 0..<300 {
            let direction = directions[rng.int(upperBound: directions.count)]
            let dr = direction.0
            let dc = direction.1

            let minRow = dr < 0 ? count - 1 : 0
            let maxRow = dr > 0 ? size - count : size - 1
            let minCol = dc < 0 ? count - 1 : 0
            let maxCol = dc > 0 ? size - count : size - 1

            if maxRow < minRow || maxCol < minCol {
                continue
            }

            let startRow = minRow + rng.int(upperBound: maxRow - minRow + 1)
            let startCol = minCol + rng.int(upperBound: maxCol - minCol + 1)

            var canPlace = true
            for index in 0..<count {
                let r = startRow + index * dr
                let c = startCol + index * dc
                let existing = board[r][c]
                if !existing.isEmpty && existing != letters[index] {
                    canPlace = false
                    break
                }
            }

            if !canPlace {
                continue
            }

            for index in 0..<count {
                let r = startRow + index * dr
                let c = startCol + index * dc
                board[r][c] = letters[index]
            }
            return true
        }

        return false
    }
}
