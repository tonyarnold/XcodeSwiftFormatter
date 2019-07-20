import Foundation

public extension UserDefaults {
    static let applicationGroupDefaults = UserDefaults(suiteName: try! SecCode.applicationGroups().first!)!
}
