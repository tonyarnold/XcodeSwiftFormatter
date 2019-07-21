//  Copyright © 2019 The CocoaBots. All rights reserved.

import Foundation
import SwiftFormatConfiguration
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    static func loadConfiguration() throws -> SwiftFormatConfiguration.Configuration {
        guard let fileURL = try configurationFileURL() else {
            return SwiftFormatConfiguration.Configuration()
        }

        return try SwiftFormatConfiguration.Configuration.decodedConfiguration(fromFileURL: fileURL)
    }

    private static func configurationFileURL() throws -> URL? {
        // First, read the regular bookmark because it could've been changed by the wrapper app.
        guard
            let regularBookmark = UserDefaults.applicationGroupDefaults.data(forKey: "RegularBookmark"),
            let securityScopedBookmark = UserDefaults.applicationGroupDefaults.data(forKey: "SecurityBookmark")
        else {
            return nil
        }

        // First, read the regular bookmark because it could've been changed by the wrapper app.
        var regularBookmarkIsStale = false
        let regularURL = try URL(resolvingBookmarkData: regularBookmark, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &regularBookmarkIsStale)

        // Then read the security URL, which is the URL we're actually going to use to access the file.
        var securityScopedBookmarkIsStale = false
        let securityScopedURL = try URL(resolvingBookmarkData: securityScopedBookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &securityScopedBookmarkIsStale)

        // Clear out the security URL if it's no longer matching the regular URL.
        guard
            regularBookmarkIsStale == false,
            securityScopedBookmarkIsStale == false,
            securityScopedURL.path == regularURL.path
        else {
            // Attempt to create new security URL from the regular URL to persist across system reboots.
            let newSecurityScopedBookmark = try regularURL.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.applicationGroupDefaults.set(newSecurityScopedBookmark, forKey: "SecurityBookmark")
            return regularURL
        }

        return securityScopedURL
    }
}
