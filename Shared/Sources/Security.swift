import Foundation
import Security

public extension SecCode {
    static func applicationGroups() throws -> [String] {
        let signingInformation = try hostCode().staticCode().signingInformation(with: [.signingInformation])
        let entitlementsDictionary = signingInformation[String(kSecCodeInfoEntitlementsDict)] as? [String: Any]

        return entitlementsDictionary?["com.apple.security.application-groups"] as? [String] ?? []
    }

    private static func hostCode(with flags: SecCSFlags = []) throws -> SecCode {
        var code: SecCode?
        let result = SecCodeCopySelf(flags, &code)
        if let code = code, result == noErr {
            return code
        } else {
            throw NSError.error(from: result)
        }
    }

    private func staticCode(with flags: SecCSFlags = []) throws -> SecStaticCode {
        var staticCode: SecStaticCode?
        let result = SecCodeCopyStaticCode(self, flags, &staticCode)
        if let staticCode = staticCode, result == noErr {
            return staticCode
        } else {
            throw NSError.error(from: result)
        }
    }
}

private extension SecCSFlags {
    static var signingInformation: SecCSFlags {
        return SecCSFlags(rawValue: kSecCSSigningInformation)
    }
}

private extension SecStaticCode {
    /// Returns the code signing information.  By default only returns "generic" information.  Pass additional flags to retrieve more information.
    /// See "Signing Information Flags" in Apple documentation for more detail.  See also the SecCode header in the SDK.
    func signingInformation(with flags: SecCSFlags = []) throws -> [String: Any] {
        var signingInformation: CFDictionary?
        let result = SecCodeCopySigningInformation(self, flags, &signingInformation)
        if let signingInformation = (signingInformation as NSDictionary?) as? [String: Any], result == noErr {
            return signingInformation
        } else {
            throw NSError.error(from: result)
        }
    }
}

private extension NSError {
    /// Creates an NSError instance for the specified `OSStatus` `status`.
    /// - parameter status: The OSStatus to convert to an NSError
    static func error(from status: OSStatus) -> Self {
        return self.init(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
    }
}
