/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/Core/Domain/Services/PuzzleFactory.swift
 - Rol principal: Implementa reglas de negocio puras del dominio (logica principal del producto).
 - Flujo simplificado: Entrada: entidades/parametros de negocio. | Proceso: aplicar reglas y restricciones del dominio. | Salida: decision o resultado de negocio.
 - Tipos clave en este archivo: PuzzleFactory,WordSearchGenerator
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

public enum PuzzleFactory {
    private static let canonicalThemes: [[String]] = [
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

    private static let englishTranslations: [String: String] = [
        "ACEITE": "OIL",
        "ALBAHACA": "BASIL",
        "ALMENDRA": "ALMOND",
        "ARBOL": "TREE",
        "ARENA": "SAND",
        "ARROZ": "RICE",
        "AUTOPISTA": "HIGHWAY",
        "AVENA": "OATMEAL",
        "AVION": "AIRPLANE",
        "BANANA": "BANANA",
        "BARRIO": "DISTRICT",
        "BICICLETA": "BICYCLE",
        "BOSQUE": "FOREST",
        "BUS": "BUS",
        "CAFE": "COFFEE",
        "CALLE": "STREET",
        "CAMINO": "PATH",
        "CARRO": "CAR",
        "CARTEL": "SIGN",
        "CEREZA": "CHERRY",
        "CHOCOLATE": "CHOCOLATE",
        "CIELO": "SKY",
        "CINE": "CINEMA",
        "CIUDAD": "CITY",
        "COCO": "COCONUT",
        "ENSALADA": "SALAD",
        "ESTACION": "STATION",
        "ESTRELLA": "STAR",
        "FLOR": "FLOWER",
        "FUEGO": "FIRE",
        "GALLETA": "COOKIE",
        "HORIZONTE": "HORIZON",
        "ISLA": "ISLAND",
        "LAGO": "LAKE",
        "LECHE": "MILK",
        "LIBRO": "BOOK",
        "LIMON": "LEMON",
        "LLUVIA": "RAIN",
        "LUNA": "MOON",
        "MANGO": "MANGO",
        "MANZANA": "APPLE",
        "MAPA": "MAP",
        "MAR": "OCEAN",
        "METRO": "SUBWAY",
        "MIEL": "HONEY",
        "MOCHILA": "BACKPACK",
        "MONTE": "HILL",
        "MOTOR": "ENGINE",
        "MUSEO": "MUSEUM",
        "MUSGO": "MOSS",
        "NARANJA": "ORANGE",
        "NIEVE": "SNOW",
        "NUBE": "CLOUD",
        "PAN": "BREAD",
        "PAPAYA": "PAPAYA",
        "PARQUE": "PARK",
        "PASEO": "WALK",
        "PASTA": "PASTA",
        "PERA": "PEAR",
        "PIMIENTO": "PEPPER",
        "PLANETA": "PLANET",
        "PLAYA": "BEACH",
        "PLAZA": "SQUARE",
        "PRIMAVERA": "SPRING",
        "PUENTE": "BRIDGE",
        "PUERTA": "DOOR",
        "QUESO": "CHEESE",
        "RAMA": "BRANCH",
        "RIO": "RIVER",
        "ROCA": "ROCK",
        "RUTA": "ROUTE",
        "SAL": "SALT",
        "SELVA": "JUNGLE",
        "SEMAFORO": "SIGNAL",
        "SOL": "SUN",
        "SOPA": "SOUP",
        "TAXI": "TAXI",
        "TIERRA": "EARTH",
        "TOMATE": "TOMATO",
        "TORRE": "TOWER",
        "TORTILLA": "OMELET",
        "TRAFICO": "TRAFFIC",
        "TREN": "TRAIN",
        "TRUENO": "THUNDER",
        "UVA": "GRAPE",
        "VALLE": "VALLEY",
        "VIAJE": "TRAVEL",
        "VIENTO": "WIND",
        "YOGUR": "YOGURT"
    ]

    private static let frenchTranslations: [String: String] = [
        "ACEITE": "HUILE",
        "ALBAHACA": "BASILIC",
        "ALMENDRA": "AMANDE",
        "ARBOL": "ARBRE",
        "ARENA": "SABLE",
        "ARROZ": "RIZ",
        "AUTOPISTA": "AUTOROUTE",
        "AVENA": "AVOINE",
        "AVION": "AVION",
        "BANANA": "BANANE",
        "BARRIO": "QUARTIER",
        "BICICLETA": "VELO",
        "BOSQUE": "FORET",
        "BUS": "AUTOBUS",
        "CAFE": "CAFE",
        "CALLE": "RUE",
        "CAMINO": "CHEMIN",
        "CARRO": "VOITURE",
        "CARTEL": "PANNEAU",
        "CEREZA": "CERISE",
        "CHOCOLATE": "CHOCOLAT",
        "CIELO": "CIEL",
        "CINE": "CINEMA",
        "CIUDAD": "VILLE",
        "COCO": "COCO",
        "ENSALADA": "SALADE",
        "ESTACION": "GARE",
        "ESTRELLA": "ETOILE",
        "FLOR": "FLEUR",
        "FUEGO": "FEU",
        "GALLETA": "BISCUIT",
        "HORIZONTE": "HORIZON",
        "ISLA": "ILE",
        "LAGO": "LAC",
        "LECHE": "LAIT",
        "LIBRO": "LIVRE",
        "LIMON": "CITRON",
        "LLUVIA": "PLUIE",
        "LUNA": "LUNE",
        "MANGO": "MANGUE",
        "MANZANA": "POMME",
        "MAPA": "CARTE",
        "MAR": "MER",
        "METRO": "METRO",
        "MIEL": "MIEL",
        "MOCHILA": "SAC",
        "MONTE": "COLLINE",
        "MOTOR": "MOTEUR",
        "MUSEO": "MUSEE",
        "MUSGO": "MOUSSE",
        "NARANJA": "ORANGE",
        "NIEVE": "NEIGE",
        "NUBE": "NUAGE",
        "PAN": "PAIN",
        "PAPAYA": "PAPAYE",
        "PARQUE": "PARC",
        "PASEO": "BALADE",
        "PASTA": "PATES",
        "PERA": "POIRE",
        "PIMIENTO": "POIVRON",
        "PLANETA": "PLANETE",
        "PLAYA": "PLAGE",
        "PLAZA": "PLACE",
        "PRIMAVERA": "PRINTEMPS",
        "PUENTE": "PONT",
        "PUERTA": "PORTE",
        "QUESO": "FROMAGE",
        "RAMA": "BRANCHE",
        "RIO": "RIVIERE",
        "ROCA": "ROCHER",
        "RUTA": "ITINERAIRE",
        "SAL": "SEL",
        "SELVA": "JUNGLE",
        "SEMAFORO": "FEU",
        "SOL": "SOLEIL",
        "SOPA": "SOUPE",
        "TAXI": "TAXI",
        "TIERRA": "TERRE",
        "TOMATE": "TOMATE",
        "TORRE": "TOUR",
        "TORTILLA": "OMELETTE",
        "TRAFICO": "TRAFIC",
        "TREN": "TRAIN",
        "TRUENO": "TONNERRE",
        "UVA": "RAISIN",
        "VALLE": "VALLEE",
        "VIAJE": "VOYAGE",
        "VIENTO": "VENT",
        "YOGUR": "YAOURT"
    ]

    private static let portugueseTranslations: [String: String] = [
        "ACEITE": "OLEO",
        "ALBAHACA": "MANJERICAO",
        "ALMENDRA": "AMENDOA",
        "ARBOL": "ARVORE",
        "ARENA": "AREIA",
        "ARROZ": "ARROZ",
        "AUTOPISTA": "AUTOESTRADA",
        "AVENA": "AVEIA",
        "AVION": "AVIAO",
        "BANANA": "BANANA",
        "BARRIO": "BAIRRO",
        "BICICLETA": "BICICLETA",
        "BOSQUE": "FLORESTA",
        "BUS": "ONIBUS",
        "CAFE": "CAFE",
        "CALLE": "RUA",
        "CAMINO": "CAMINHO",
        "CARRO": "CARRO",
        "CARTEL": "CARTAZ",
        "CEREZA": "CEREJA",
        "CHOCOLATE": "CHOCOLATE",
        "CIELO": "CEU",
        "CINE": "CINEMA",
        "CIUDAD": "CIDADE",
        "COCO": "COCO",
        "ENSALADA": "SALADA",
        "ESTACION": "ESTACAO",
        "ESTRELLA": "ESTRELA",
        "FLOR": "FLOR",
        "FUEGO": "FOGO",
        "GALLETA": "BISCOITO",
        "HORIZONTE": "HORIZONTE",
        "ISLA": "ILHA",
        "LAGO": "LAGO",
        "LECHE": "LEITE",
        "LIBRO": "LIVRO",
        "LIMON": "LIMAO",
        "LLUVIA": "CHUVA",
        "LUNA": "LUA",
        "MANGO": "MANGA",
        "MANZANA": "MACA",
        "MAPA": "MAPA",
        "MAR": "MAR",
        "METRO": "METRO",
        "MIEL": "MEL",
        "MOCHILA": "MOCHILA",
        "MONTE": "COLINA",
        "MOTOR": "MOTOR",
        "MUSEO": "MUSEU",
        "MUSGO": "MUSGO",
        "NARANJA": "LARANJA",
        "NIEVE": "NEVE",
        "NUBE": "NUVEM",
        "PAN": "PAO",
        "PAPAYA": "PAPAIA",
        "PARQUE": "PARQUE",
        "PASEO": "PASSEIO",
        "PASTA": "MASSA",
        "PERA": "PERA",
        "PIMIENTO": "PIMENTAO",
        "PLANETA": "PLANETA",
        "PLAYA": "PRAIA",
        "PLAZA": "PRACA",
        "PRIMAVERA": "PRIMAVERA",
        "PUENTE": "PONTE",
        "PUERTA": "PORTA",
        "QUESO": "QUEIJO",
        "RAMA": "RAMO",
        "RIO": "RIO",
        "ROCA": "ROCHA",
        "RUTA": "ROTA",
        "SAL": "SAL",
        "SELVA": "SELVA",
        "SEMAFORO": "SEMAFORO",
        "SOL": "SOL",
        "SOPA": "SOPA",
        "TAXI": "TAXI",
        "TIERRA": "TERRA",
        "TOMATE": "TOMATE",
        "TORRE": "TORRE",
        "TORTILLA": "OMELETE",
        "TRAFICO": "TRAFEGO",
        "TREN": "TREM",
        "TRUENO": "TROVAO",
        "UVA": "UVA",
        "VALLE": "VALE",
        "VIAJE": "VIAGEM",
        "VIENTO": "VENTO",
        "YOGUR": "IOGURTE"
    ]

    private static let spanishThemes: [[String]] = canonicalThemes.map { theme in
        theme.map(WordSearchNormalization.normalizedWord)
    }

    private static let englishThemes: [[String]] = localizedThemes(using: englishTranslations)
    private static let frenchThemes: [[String]] = localizedThemes(using: frenchTranslations)
    private static let portugueseThemes: [[String]] = localizedThemes(using: portugueseTranslations)

    private static func localizedThemes(using translations: [String: String]) -> [[String]] {
        canonicalThemes.map { theme in
            theme.map { rawWord in
                let canonical = WordSearchNormalization.normalizedWord(rawWord)
                let translated = translations[canonical] ?? canonical
                return WordSearchNormalization.normalizedWord(translated)
            }
        }
    }

    private static let canonicalByLocalizedWord: [String: String] = {
        var map: [String: String] = [:]
        for theme in canonicalThemes {
            for rawWord in theme {
                let canonical = WordSearchNormalization.normalizedWord(rawWord)
                map[canonical] = canonical
            }
        }

        for translations in [englishTranslations, frenchTranslations, portugueseTranslations] {
            for (canonical, translated) in translations {
                map[WordSearchNormalization.normalizedWord(translated)] = canonical
            }
        }
        return map
    }()

    public static func canonicalWord(for localizedWord: String) -> String? {
        let normalized = WordSearchNormalization.normalizedWord(localizedWord)
        return canonicalByLocalizedWord[normalized]
    }

    public static func normalizedPuzzleIndex(_ offset: Int) -> Int {
        let count = max(canonicalThemes.count, 1)
        let value = offset % count
        return value >= 0 ? value : value + count
    }

    public static func puzzle(for dayKey: DayKey, gridSize: Int, locale: Locale? = nil) -> Puzzle {
        let normalizedIndex = normalizedPuzzleIndex(dayKey.offset)
        let clampedGridSize = clampGridSize(gridSize)
        let wordsPool = themedWords(for: normalizedIndex, locale: locale)
        let seed = stableSeed(dayOffset: dayKey.offset, gridSize: clampedGridSize)

        let selectedWords = selectWords(from: wordsPool, gridSize: clampedGridSize, seed: seed)
        let generated = WordSearchGenerator.generate(gridSize: clampedGridSize, words: selectedWords, seed: seed)

        return Puzzle(
            number: normalizedIndex + 1,
            dayKey: dayKey,
            grid: PuzzleGrid(letters: generated.grid),
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

    private static func themedWords(for index: Int, locale: Locale?) -> [String] {
        let resolvedLocale = locale ?? AppLocalization.currentLocale
        switch AppLanguage.resolved(from: resolvedLocale) {
        case .spanish:
            return spanishThemes[index]
        case .french:
            return frenchThemes[index]
        case .portuguese:
            return portugueseThemes[index]
        case .english:
            return englishThemes[index]
        }
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
