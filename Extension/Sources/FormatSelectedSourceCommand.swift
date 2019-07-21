//  Copyright © 2019 The CocoaBots. All rights reserved.

import Basic
import Foundation
import SwiftFormat
import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax
import XcodeKit

class FormatSelectedSourceCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard ["public.swift-source", "com.apple.dt.playground", "com.apple.dt.playgroundpage"].contains(invocation.buffer.contentUTI) else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            return completionHandler(FormatCommandError.noSelection)
        }

        // Grab the selected source to format using entire lines of text
        let selectionRange = selection.start.line ... min(selection.end.line, invocation.buffer.lines.count - 1)
        let sourceToFormat = selectionRange.flatMap {
            (invocation.buffer.lines[$0] as? String).map { [$0] } ?? []
        }.joined()

        let work = DispatchWorkItem {
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
                invocation.buffer.lines.removeObjects(in: NSMakeRange(selection.start.line, selectionRange.count))
                invocation.buffer.lines.insert(formattedSource, at: selection.start.line)

                let updatedSelectionRange = self.rangeForDifferences(
                    in: selection, between: sourceToFormat, and: formattedSource
                )

                invocation.buffer.selections.add(updatedSelectionRange)

                return completionHandler(nil)
            } catch {
                return completionHandler(error)
            }
        }

        // Workaround for https://bugs.swift.org/browse/SR-11170
        // SyntaxRewriter visitation exhausts the stack space that dispatch threads get
        let thread = Foundation.Thread {
            work.perform()
        }
        thread.stackSize = 8 << 20 // 8 MB.
        thread.start()
        work.wait()
    }

    /// Given a source text range, an original source string and a modified target string this
    /// method will calculate the differences, and return a usable XCSourceTextRange based upon the original.
    ///
    /// - Parameters:
    ///   - textRange: Existing source text range
    ///   - sourceText: Original text
    ///   - targetText: Modified text
    /// - Returns: Source text range that should be usable with the passed modified text
    private func rangeForDifferences(
        in textRange: XCSourceTextRange,
        between _: String, and targetText: String
    ) -> XCSourceTextRange {
        // Ensure that we're not greedy about end selections — this can cause empty lines to be removed
        let lineCountOfTarget = targetText.components(separatedBy: CharacterSet.newlines).count
        let finalLine = (textRange.end.column > 0) ? textRange.end.line : textRange.end.line - 1
        let range = textRange.start.line ... finalLine
        let difference = range.count - lineCountOfTarget
        let start = XCSourceTextPosition(line: textRange.start.line, column: 0)
        let end = XCSourceTextPosition(line: finalLine - difference, column: 0)

        return XCSourceTextRange(start: start, end: end)
    }
}
