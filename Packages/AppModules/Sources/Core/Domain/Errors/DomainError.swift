import Foundation

public enum DomainError: Error, Equatable, Sendable {
    case invalidGrid
    case invalidSelection
    case wordNotFound
    case duplicateWord
    case persistenceUnavailable
    case decodeFailure
    case encodeFailure
    case migrationFailure
}
