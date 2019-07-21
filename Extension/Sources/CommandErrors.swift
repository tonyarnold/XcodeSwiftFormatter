import Foundation

enum FormatCommandError: Error, LocalizedError, CustomNSError {
    case notSwiftLanguage
    case noSelection
    case invalidSelection

    var localizedDescription: String {
        switch self {
        case .notSwiftLanguage:
            return "Error: not a Swift source file."
        case .noSelection:
            return "Error: no text selected."
        case .invalidSelection:
            return "Error: invalid selection."
        }
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: localizedDescription]
    }
}
