import Foundation

enum FormatCommandError: Error, LocalizedError, CustomNSError {
    case notSwiftLanguage(String)
    case noSelection
    case invalidSelection

    var localizedDescription: String {
        switch self {
        case let .notSwiftLanguage(contentUTI):
            return "Error: not a Swift source file. Current file is \(contentUTI)."
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
