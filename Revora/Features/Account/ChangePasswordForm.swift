struct ChangePasswordForm: Equatable {
    enum Field: CaseIterable {
        case currentPassword, newPassword, confirmPassword
    }

    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""

    /// What the field still needs, or `nil` when it's valid. Only the server can tell
    /// whether the current password is right, so here it only has to be filled in.
    func issue(for field: Field) -> String? {
        switch field {
        case .currentPassword:
            currentPassword.isEmpty ? "Enter your current password." : nil
        case .newPassword:
            if newPassword.count < AuthService.minimumPasswordLength {
                RegisterForm.passwordRequirement
            } else if newPassword == currentPassword {
                "Choose a password that's different from your current one."
            } else {
                nil
            }
        case .confirmPassword:
            confirmPassword.isEmpty || confirmPassword != newPassword
                ? "Make sure both passwords match."
                : nil
        }
    }

    var isValid: Bool {
        Field.allCases.allSatisfy { issue(for: $0) == nil }
    }
}
