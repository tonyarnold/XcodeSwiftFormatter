//  Copyright © 2019 The CocoaBots. All rights reserved.

import Basic
import Foundation
import SwiftFormat
import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax
import XcodeKit

class FormatEntireFileCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard ["public.swift-source", "com.apple.dt.playground", "com.apple.dt.playgroundpage"].contains(invocation.buffer.contentUTI) else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        // Grab the entire file's contents
        let sourceToFormat = invocation.buffer.completeBuffer

        do {
            let configuration = try SourceEditorExtension.loadConfiguration()
            let formatter = SwiftFormatter(configuration: configuration)
            let syntax = try SyntaxParser.parse(source: sourceToFormat)
            var buffer = BufferedOutputByteStream()
            // This isn't great - but Xcode doesn't give us the path to the currently edited file
            let dummyFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".swift")
            try formatter.format(syntax: syntax, assumingFileURL: dummyFileURL, to: &buffer)
            buffer.flush()

            guard
                let formattedSource = buffer.bytes.validDescription,
                formattedSource != sourceToFormat
            else {
                // No changes needed
                return completionHandler(nil)
            }

            // Remove all selections to avoid a crash when changing the contents of the buffer.
            invocation.buffer.selections.removeAllObjects()

            // Update buffer
            invocation.buffer.completeBuffer = formattedSource

            // For the time being, set the selection back to the last character of the buffer
            guard let lastLine = invocation.buffer.lines.lastObject as? String else {
                return completionHandler(FormatCommandError.invalidSelection)
            }
            let position = XCSourceTextPosition(line: invocation.buffer.lines.count - 1, column: lastLine.count)
            let updatedSelectionRange = XCSourceTextRange(start: position, end: position)
            invocation.buffer.selections.add(updatedSelectionRange)

            return completionHandler(nil)
        } catch {
            return completionHandler(error)
        }
    }
}
