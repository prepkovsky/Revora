import Foundation

struct LoginForm: Equatable {
    enum Field: CaseIterable {
        case email, password
    }

    var email = ""
    var password = ""

    var trimmedEmail: String {
        EmailAddress.trimmed(email)
    }

    /// What the field still needs, or `nil` when it's valid. The password isn't checked
    /// against the sign-up rules, so accounts made under older rules can still log in.
    func issue(for field: Field) -> String? {
        switch field {
        case .email:
            EmailAddress.isValid(trimmedEmail) ? nil : EmailAddress.requirement
        case .password:
            password.isEmpty ? "Enter your password." : nil
        }
    }

    var isValid: Bool {
        Field.allCases.allSatisfy { issue(for: $0) == nil }
    }
}
