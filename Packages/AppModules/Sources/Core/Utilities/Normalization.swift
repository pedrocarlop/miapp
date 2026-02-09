import Foundation

public enum WordSearchNormalization {
    public static func normalizedWord(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: .current)
            .uppercased()
    }

    public static func normalizedWords<S: Sequence>(_ words: S) -> [String] where S.Element == String {
        words.map(normalizedWord)
    }
}
