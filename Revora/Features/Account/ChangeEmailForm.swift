import Foundation

struct ChangeEmailForm: Equatable {
    enum Field: CaseIterable {
        case newEmail, password
    }

    /// The email the account has now, which the new one has to differ from.
    var currentEmail: String?
    var newEmail = ""
    var password = ""

    var trimmedEmail: String {
        EmailAddress.trimmed(newEmail)
    }

    /// What the field still needs, or `nil` when it's valid.
    func issue(for field: Field) -> String? {
        switch field {
        case .newEmail:
            if let issue = EmailAddress.issue(for: trimmedEmail) {
                issue
            } else if let currentEmail, trimmedEmail.caseInsensitiveCompare(currentEmail) == .orderedSame {
                // Firebase treats emails as case-insensitive.
                "That's already your email."
            } else {
                nil
            }
        case .password:
            password.isEmpty ? "Enter your password." : nil
        }
    }

    var isValid: Bool {
        Field.allCases.allSatisfy { issue(for: $0) == nil }
    }
}
