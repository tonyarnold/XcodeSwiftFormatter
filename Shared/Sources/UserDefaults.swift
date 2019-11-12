import Foundation

extension UserDefaults {
    public static let applicationGroupDefaults = UserDefaults(suiteName: try! SecCode.applicationGroups().first!)!
}
