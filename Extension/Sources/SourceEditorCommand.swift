//  Copyright © 2019 The CocoaBots. All rights reserved.

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.

        completionHandler(nil)
    }
}
