import Testing
@testable import Revora

struct ChangePasswordFormTests {
    private let newPassword = String(repeating: "n", count: AuthService.minimumPasswordLength)

    private func validForm() -> ChangePasswordForm {
        ChangePasswordForm(currentPassword: "current-password", newPassword: newPassword, confirmPassword: newPassword)
    }

    @Test func validFormHasNoIssues() {
        let form = validForm()
        #expect(form.isValid)
        for field in ChangePasswordForm.Field.allCases {
            #expect(form.issue(for: field) == nil)
        }
    }

    /// Any length is fine: older accounts may predate the minimum, and only the server can check it.
    @Test func currentPasswordOnlyNeedsFillingIn() {
        var form = validForm()
        form.currentPassword = "short"
        #expect(form.issue(for: .currentPassword) == nil)
        form.currentPassword = ""
        #expect(form.issue(for: .currentPassword) != nil)
        #expect(!form.isValid)
    }

    @Test func requiresMinimumNewPasswordLength() {
        var form = validForm()
        form.newPassword = String(newPassword.dropLast())
        form.confirmPassword = form.newPassword
        #expect(form.issue(for: .newPassword) == RegisterForm.passwordRequirement)
        #expect(!form.isValid)
    }

    @Test func newPasswordMustDifferFromCurrent() {
        var form = validForm()
        form.currentPassword = newPassword
        #expect(form.issue(for: .newPassword) != nil)
        #expect(!form.isValid)
    }

    @Test func requiresMatchingNewPasswords() {
        var form = validForm()
        form.confirmPassword = newPassword + "x"
        #expect(form.issue(for: .confirmPassword) != nil)
        form.confirmPassword = ""
        #expect(form.issue(for: .confirmPassword) != nil)
        #expect(!form.isValid)
    }
}
