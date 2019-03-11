import Foundation

public enum MainError: Error, LocalizedError {
    case fatalError(description: String)

    public var errorDescription: String? {
        switch self {
        case let .fatalError(message):
            return message
        }
    }
}
