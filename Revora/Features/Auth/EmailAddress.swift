import Foundation

enum EmailAddress {
    static let requirement = "Enter an email like name@example.com."

    /// A loose shape check to catch typos early. Firebase has the final say.
    static func isValid(_ email: String) -> Bool {
        email.wholeMatch(of: /[^\s@]+@[^\s@]+\.[^\s@]{2,}/) != nil
    }

    /// AutoFill and pasting can add stray spaces around an email.
    static func trimmed(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
