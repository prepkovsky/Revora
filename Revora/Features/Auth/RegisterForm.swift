struct RegisterForm: Equatable {
    enum Field: CaseIterable {
        case name, email, password, confirmPassword
    }

    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""

    var trimmedName: String {
        PersonName.trimmed(name)
    }

    var trimmedEmail: String {
        EmailAddress.trimmed(email)
    }

    static var passwordRequirement: String {
        "Use at least \(AuthService.minimumPasswordLength) characters."
    }

    /// What the field still needs, or `nil` when it's valid.
    func issue(for field: Field) -> String? {
        switch field {
        case .name:
            PersonName.issue(for: trimmedName)
        case .email:
            EmailAddress.issue(for: trimmedEmail)
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
