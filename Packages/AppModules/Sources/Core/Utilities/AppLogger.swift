import Foundation

public enum AppLogLevel: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case error = "ERROR"
}

public enum AppLogCategory: String, Sendable {
    case persistence
    case migration
    case state
    case ui
    case general
}

public enum AppLogger {
    public static func debug(
        _ message: String,
        category: AppLogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #fileID,
        line: UInt = #line
    ) {
        log(
            level: .debug,
            message: message,
            category: category,
            metadata: metadata,
            file: file,
            line: line
        )
    }

    public static func info(
        _ message: String,
        category: AppLogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #fileID,
        line: UInt = #line
    ) {
        log(
            level: .info,
            message: message,
            category: category,
            metadata: metadata,
            file: file,
            line: line
        )
    }

    public static func error(
        _ message: String,
        category: AppLogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #fileID,
        line: UInt = #line
    ) {
        log(
            level: .error,
            message: message,
            category: category,
            metadata: metadata,
            file: file,
            line: line
        )
    }

    private static func log(
        level: AppLogLevel,
        message: String,
        category: AppLogCategory,
        metadata: [String: String],
        file: String,
        line: UInt
    ) {
        let metadataText = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        let context = "[\(category.rawValue)] \(file):\(line)"
        let finalMessage: String
        if metadataText.isEmpty {
            finalMessage = "[\(level.rawValue)] \(context) - \(message)"
        } else {
            finalMessage = "[\(level.rawValue)] \(context) - \(message) {\(metadataText)}"
        }

#if DEBUG
        print(finalMessage)
        if level == .error {
            assertionFailure(finalMessage)
        }
#else
        if level == .error {
            NSLog("%@", finalMessage)
        }
#endif
    }
}
