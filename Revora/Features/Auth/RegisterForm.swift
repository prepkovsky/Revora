import Foundation

struct RegisterForm: Equatable {
    enum Field: CaseIterable {
        case email, password, confirmPassword
    }

    var email = ""
    var password = ""
    var confirmPassword = ""

    /// AutoFill and pasting can add stray spaces around an email.
    var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var passwordRequirement: String {
        "Use at least \(AuthService.minimumPasswordLength) characters."
    }

    /// What the field still needs, or `nil` when it's valid.
    func issue(for field: Field) -> String? {
        switch field {
        case .email:
            trimmedEmail.wholeMatch(of: /[^\s@]+@[^\s@]+\.[^\s@]{2,}/) == nil
                ? "Enter an email like name@example.com."
                : nil
        case .password:
            password.count < AuthService.minimumPasswordLength ? Self.passwordRequirement : nil
        case .confirmPassword:
            confirmPassword.isEmpty || confirmPassword != password
                ? "Make sure both passwords match."
                : nil
        }
    }

    var isValid: Bool {
        Field.allCases.allSatisfy { issue(for: $0) == nil }
    }
}
