import Foundation

enum EmailAddress {
    static let missing = "Enter your email."

    static var requirement: String {
        AuthError.invalidEmail.message
    }

    /// What a trimmed email still needs, or `nil` when it looks right.
    static func issue(for email: String) -> String? {
        if email.isEmpty { return missing }
        return isValid(email) ? nil : requirement
    }

    /// A loose shape check to catch typos early. Firebase has the final say.
    private static func isValid(_ email: String) -> Bool {
        email.wholeMatch(of: /[^\s@]+@[^\s@]+\.[^\s@]{2,}/) != nil
    }

    /// AutoFill and pasting can add stray spaces around an email.
    static func trimmed(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
