import Testing
@testable import Revora

struct RegisterFormTests {
    private let validPassword = String(repeating: "a", count: AuthService.minimumPasswordLength)

    private func validForm() -> RegisterForm {
        RegisterForm(email: "name@example.com", password: validPassword, confirmPassword: validPassword)
    }

    @Test func validFormHasNoIssues() {
        let form = validForm()
        #expect(form.isValid)
        for field in RegisterForm.Field.allCases {
            #expect(form.issue(for: field) == nil)
        }
    }

    @Test(arguments: ["", "name", "name@", "name@example", "name@example.c", "na me@example.com", "@example.com"])
    func rejectsInvalidEmails(_ email: String) {
        var form = validForm()
        form.email = email
        #expect(form.issue(for: .email) != nil)
        #expect(!form.isValid)
    }

    @Test(arguments: ["name@example.com", "first.last+tag@mail.example.co.uk"])
    func acceptsValidEmails(_ email: String) {
        var form = validForm()
        form.email = email
        #expect(form.issue(for: .email) == nil)
    }

    @Test func trimsWhitespaceAroundEmail() {
        var form = validForm()
        form.email = "  name@example.com \n"
        #expect(form.trimmedEmail == "name@example.com")
        #expect(form.issue(for: .email) == nil)
    }

    @Test func requiresMinimumPasswordLength() {
        var form = validForm()
        form.password = String(validPassword.dropLast())
        form.confirmPassword = form.password
        #expect(form.issue(for: .password) == RegisterForm.passwordRequirement)
        #expect(!form.isValid)
    }

    @Test func requiresMatchingPasswords() {
        var form = validForm()
        form.confirmPassword = validPassword + "b"
        #expect(form.issue(for: .confirmPassword) != nil)
        #expect(!form.isValid)
    }

    @Test func requiresConfirmPassword() {
        var form = validForm()
        form.confirmPassword = ""
        #expect(form.issue(for: .confirmPassword) != nil)
    }
}
