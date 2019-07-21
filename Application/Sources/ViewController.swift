import Cocoa

class ViewController: NSViewController {
    @IBOutlet var configurationFilePathControl: NSPathControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        var isStale = false

        guard
            let bookmark = UserDefaults.applicationGroupDefaults.data(forKey: "SecurityBookmark"),
            let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &isStale),
            url.startAccessingSecurityScopedResource()
        else {
            // Remove the bookmark value from the storage
            UserDefaults.applicationGroupDefaults.removeObject(forKey: "RegularBookmark")
            return
        }

        // Regenerate the bookmark, so that the extension can read a valid bookmark after a system restart.
        let regularBookmark = try? url.bookmarkData()
        url.stopAccessingSecurityScopedResource()
        UserDefaults.applicationGroupDefaults.set(regularBookmark, forKey: "RegularBookmark")
        configurationFilePathControl.url = url
    }

    @IBAction func selectConfiguration(_ sender: NSPathControl) {
        guard
            let url = sender.url,
            let configurationFileURL = findConfigurationFile(from: url)
        else {
            return
        }

        selectURL(configurationFileURL)
    }

    // MARK: - Private Implementation -

    fileprivate func createBookmark(from url: URL) throws -> Data {
        // Create a bookmark and store into defaults.
        return try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    @discardableResult
    private func selectURL(_ url: URL) -> Bool {
        guard let bookmark = try? createBookmark(from: url) else {
            return false
        }

        configurationFilePathControl.url = url
        UserDefaults.applicationGroupDefaults.set(bookmark, forKey: "SecurityBookmark")
        UserDefaults.applicationGroupDefaults.set(try? url.bookmarkData(), forKey: "RegularBookmark")

        return true
    }

    fileprivate func findConfigurationFile(from url: URL) -> URL? {
        guard
            let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
            resourceValues.isDirectory ?? false
        else {
            return url
        }

        return url.appendingPathComponent(".swift-format")
    }
}

extension ViewController: NSPathControlDelegate {
    func pathControl(_ pathControl: NSPathControl, willDisplay openPanel: NSOpenPanel) {
        openPanel.title = NSLocalizedString("Choose a custom Swift Format JSON configuration file", comment: "Title for open panel when selecting a custom configuration file")
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.showsHiddenFiles = true
        openPanel.treatsFilePackagesAsDirectories = true
        openPanel.allowsMultipleSelection = false
    }

    func pathControl(_ pathControl: NSPathControl, validateDrop info: NSDraggingInfo) -> NSDragOperation {
        guard
            let url = NSURL(from: info.draggingPasteboard),
            let configurationFileURL = findConfigurationFile(from: url as URL),
            let _ = try? createBookmark(from: configurationFileURL)
        else {
            return []
        }

        return .copy
    }
}
