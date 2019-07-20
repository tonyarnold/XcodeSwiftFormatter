//  Copyright © 2019 The CocoaBots. All rights reserved.

import Foundation
import SwiftFormatConfiguration

public extension SwiftFormatConfiguration.Configuration {
    /// Loads and returns a `Configuration` from the given JSON file if it is found and is valid. If the file does not exist or there was an error decoding it, the program exits with a non-zero exit code.
    static func decodedConfiguration(fromFileAtPath path: String) throws -> SwiftFormatConfiguration.Configuration {
        let url = URL(fileURLWithPath: path)
        return try decodedConfiguration(fromFileURL: url)
    }

    /// Loads and returns a `Configuration` from the given JSON file if it is found and is valid. If the file does not exist or there was an error decoding it, the program exits with a non-zero exit code.
    static func decodedConfiguration(fromFileURL fileURL: URL) throws -> SwiftFormatConfiguration.Configuration {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(SwiftFormatConfiguration.Configuration.self, from: data)
    }
}

