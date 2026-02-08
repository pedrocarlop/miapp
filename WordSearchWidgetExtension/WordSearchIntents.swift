//
//  WordSearchIntents.swift
//  WordSearchWidgetExtension
//
//  AppIntents and shared game logic for the interactive word-search widget.
//

import Foundation
import AppIntents
import WidgetKit

@available(iOS 17.0, *)
enum WordSearchSlot: String, CaseIterable, AppEnum {
    case a
    case b
    case c

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Partida")

    static var caseDisplayRepresentations: [WordSearchSlot: DisplayRepresentation] = [
        .a: DisplayRepresentation(title: "Partida A"),
        .b: DisplayRepresentation(title: "Partida B"),
        .c: DisplayRepresentation(title: "Partida C")
    ]

    var title: String { rawValue.uppercased() }
}

@available(iOS 17.0, *)
struct WordSearchWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configurar Sopa de letras"
    static var description = IntentDescription("Configura el slot para esta instancia del widget.")

    @Parameter(title: "Partida")
    var slot: WordSearchSlot

    init() {
        self.slot = .a
    }
}

@available(iOS 17.0, *)
struct ToggleCellIntent: AppIntent {
    static var title: LocalizedStringResource = "Seleccionar letra"

    @Parameter(title: "Partida") var slot: WordSearchSlot
    @Parameter(title: "Fila") var row: Int
    @Parameter(title: "Columna") var col: Int

    init() {}

    init(slot: WordSearchSlot, row: Int, col: Int) {
        self.slot = slot
        self.row = row
        self.col = col
    }

    func perform() async throws -> some IntentResult {
        var state = WordSearchPersistence.loadState(for: slot)
        let position = WordSearchPosition(r: row, c: col)
        if state.selected.contains(position) {
            state.selected.remove(position)
        } else {
            state.selected.insert(position)
        }
        WordSearchPersistence.save(state, for: slot)
        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        return .result()
    }
}

@available(iOS 17.0, *)
struct ConfirmSelectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Comprobar seleccion"

    @Parameter(title: "Partida") var slot: WordSearchSlot

    init() {}

    init(slot: WordSearchSlot) {
        self.slot = slot
    }

    func perform() async throws -> some IntentResult {
        var state = WordSearchPersistence.loadState(for: slot)
        if let word = WordSearchLogic.wordFromSelection(state: state) {
            state.foundWords.insert(word)
        }
        state.selected.removeAll()
        WordSearchPersistence.save(state, for: slot)
        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        return .result()
    }
}

@available(iOS 17.0, *)
struct ResetPuzzleIntent: AppIntent {
    static var title: LocalizedStringResource = "Reiniciar"

    @Parameter(title: "Partida") var slot: WordSearchSlot

    init() {}

    init(slot: WordSearchSlot) {
        self.slot = slot
    }

    func perform() async throws -> some IntentResult {
        _ = WordSearchPersistence.advanceToNextPuzzle(for: slot)
        WidgetCenter.shared.reloadTimelines(ofKind: WordSearchConstants.widgetKind)
        return .result()
    }
}

@available(iOS 17.0, *)
enum WordSearchConstants {
    static let suiteName = "group.miapp.wordsearch"
    static let widgetKind = "WordSearchWidget"
    static let legacyStateKey = "puzzle_state_v1"
    static let migrationFlagKey = "puzzle_v2_migrated_legacy"
}

@available(iOS 17.0, *)
struct WordSearchPosition: Hashable, Codable {
    let r: Int
    let c: Int
}

@available(iOS 17.0, *)
struct WordSearchState: Codable, Equatable {
    var grid: [[Character]]
    var words: [String]
    var selected: Set<WordSearchPosition>
    var foundWords: Set<String>
    var puzzleIndex: Int

    var foundCount: Int {
        foundWords.intersection(normalizedWords).count
    }

    var totalWords: Int {
        normalizedWords.count
    }

    var isCompleted: Bool {
        totalWords > 0 && foundCount == totalWords
    }

    var progressText: String {
        "\(foundCount)/\(totalWords)"
    }

    private var normalizedWords: Set<String> {
        Set(words.map { $0.uppercased() })
    }
}

@available(iOS 17.0, *)
struct WordSearchPuzzle {
    let grid: [[Character]]
    let words: [String]
}

@available(iOS 17.0, *)
enum WordSearchPuzzleBank {
    static let puzzles: [WordSearchPuzzle] = [
        build(
            [
                "S O P A D E L E",
                "A R B O L X X X",
                "L I B R O X X X",
                "X X X M A R X X",
                "X X X X X X X X",
                "C A S A X X X X",
                "X X X X P A N X",
                "X X X X X X X X"
            ],
            words: ["sopa", "arbol", "libro", "mar", "casa", "pan"]
        ),
        build(
            [
                "S O L Q W E R T",
                "L U N A A S D F",
                "M A R Z X C V B",
                "F L O R N M A S",
                "R I O Q W E R T",
                "N U B E A S D F",
                "P L A Y Q W E R",
                "T I E M P O X C"
            ],
            words: ["sol", "luna", "mar", "flor", "rio", "nube"]
        ),
        build(
            [
                "C A F E P Q R S",
                "T E U I O P A S",
                "P A N D F G H J",
                "M I E L K L M N",
                "U V A Q W E R T",
                "Q U E S O Y U I",
                "C A M P O A S D",
                "R U T A F G H J"
            ],
            words: ["cafe", "te", "pan", "miel", "uva", "queso"]
        )
    ]

    static func puzzle(at index: Int) -> WordSearchPuzzle {
        let safeIndex = normalizedIndex(index)
        return puzzles[safeIndex]
    }

    static func normalizedIndex(_ index: Int) -> Int {
        let count = max(puzzles.count, 1)
        let value = index % count
        return value >= 0 ? value : value + count
    }

    private static func build(_ rows: [String], words: [String]) -> WordSearchPuzzle {
        let grid = rows.map { $0.split(separator: " ").map { Character(String($0)) } }
        return WordSearchPuzzle(grid: grid, words: words)
    }
}

@available(iOS 17.0, *)
enum WordSearchPersistence {
    static func loadState(for slot: WordSearchSlot) -> WordSearchState {
        guard let defaults = UserDefaults(suiteName: WordSearchConstants.suiteName) else {
            return makeState(puzzleIndex: 0)
        }
        migrateLegacyIfNeeded(defaults: defaults)

        if let data = defaults.data(forKey: stateKey(for: slot)),
           let decoded = try? JSONDecoder().decode(WordSearchState.self, from: data) {
            let normalizedIndex = WordSearchPuzzleBank.normalizedIndex(decoded.puzzleIndex)
            if normalizedIndex != decoded.puzzleIndex {
                var fixed = decoded
                fixed.puzzleIndex = normalizedIndex
                save(fixed, for: slot)
                return fixed
            }
            return decoded
        }

        let index = defaults.integer(forKey: indexKey(for: slot))
        let state = makeState(puzzleIndex: index)
        save(state, for: slot)
        return state
    }

    static func save(_ state: WordSearchState, for slot: WordSearchSlot) {
        guard let defaults = UserDefaults(suiteName: WordSearchConstants.suiteName),
              let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey(for: slot))
        defaults.set(state.puzzleIndex, forKey: indexKey(for: slot))
    }

    static func advanceToNextPuzzle(for slot: WordSearchSlot) -> WordSearchState {
        guard let defaults = UserDefaults(suiteName: WordSearchConstants.suiteName) else {
            return makeState(puzzleIndex: 0)
        }
        migrateLegacyIfNeeded(defaults: defaults)
        let current = loadState(for: slot)
        let nextIndex = WordSearchPuzzleBank.normalizedIndex(current.puzzleIndex + 1)
        let next = makeState(puzzleIndex: nextIndex)
        save(next, for: slot)
        return next
    }

    private static func migrateLegacyIfNeeded(defaults: UserDefaults) {
        if defaults.bool(forKey: WordSearchConstants.migrationFlagKey) {
            return
        }
        defer {
            defaults.set(true, forKey: WordSearchConstants.migrationFlagKey)
        }

        guard let legacyData = defaults.data(forKey: WordSearchConstants.legacyStateKey),
              let legacyState = try? JSONDecoder().decode(LegacyPuzzleState.self, from: legacyData) else {
            return
        }

        let migrated = WordSearchState(
            grid: legacyState.grid,
            words: legacyState.words,
            selected: Set(legacyState.selected.map { WordSearchPosition(r: $0.r, c: $0.c) }),
            foundWords: Set(legacyState.foundWords.map { $0.uppercased() }),
            puzzleIndex: 0
        )
        save(migrated, for: .a)
        defaults.removeObject(forKey: WordSearchConstants.legacyStateKey)
    }

    private static func makeState(puzzleIndex: Int) -> WordSearchState {
        let normalized = WordSearchPuzzleBank.normalizedIndex(puzzleIndex)
        let puzzle = WordSearchPuzzleBank.puzzle(at: normalized)
        return WordSearchState(
            grid: puzzle.grid,
            words: puzzle.words,
            selected: [],
            foundWords: [],
            puzzleIndex: normalized
        )
    }

    private static func stateKey(for slot: WordSearchSlot) -> String {
        "puzzle_state_v2_\(slot.rawValue)"
    }

    private static func indexKey(for slot: WordSearchSlot) -> String {
        "puzzle_index_v2_\(slot.rawValue)"
    }
}

@available(iOS 17.0, *)
enum WordSearchLogic {
    static func wordFromSelection(state: WordSearchState) -> String? {
        let positions = state.selected.sorted { lhs, rhs in
            if lhs.r == rhs.r { return lhs.c < rhs.c }
            return lhs.r < rhs.r
        }
        guard positions.count >= 2 else { return nil }

        let dr = positions[1].r - positions[0].r
        let dc = positions[1].c - positions[0].c
        let stepR = dr == 0 ? 0 : (dr > 0 ? 1 : -1)
        let stepC = dc == 0 ? 0 : (dc > 0 ? 1 : -1)
        if stepR == 0 && stepC == 0 { return nil }

        for index in 1..<positions.count {
            let deltaR = positions[index].r - positions[index - 1].r
            let deltaC = positions[index].c - positions[index - 1].c
            if deltaR != stepR || deltaC != stepC { return nil }
        }

        let letters = positions.map { state.grid[$0.r][$0.c] }
        let candidate = String(letters).uppercased()
        let allowed = Set(state.words.map { $0.uppercased() })
        if allowed.contains(candidate) { return candidate }
        let reverse = String(candidate.reversed())
        if allowed.contains(reverse) { return reverse }
        return nil
    }
}

@available(iOS 17.0, *)
private struct LegacyPosition: Hashable, Codable {
    let r: Int
    let c: Int
}

@available(iOS 17.0, *)
private struct LegacyPuzzleState: Codable {
    var grid: [[Character]]
    var words: [String]
    var selected: Set<LegacyPosition>
    var foundWords: Set<String>
}
