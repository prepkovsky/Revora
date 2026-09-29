import Testing
@testable import Revora

struct LoginFormTests {
    @Test func validFormHasNoIssues() {
        let form = LoginForm(email: " name@example.com ", password: "x")
        #expect(form.isValid)
        #expect(form.trimmedEmail == "name@example.com")
    }

    @Test func requiresValidEmail() {
        let form = LoginForm(email: "name@", password: "x")
        #expect(form.issue(for: .email) == EmailAddress.requirement)
        #expect(!form.isValid)
    }

    @Test func requiresPassword() {
        let form = LoginForm(email: "name@example.com", password: "")
        #expect(form.issue(for: .password) != nil)
        #expect(!form.isValid)
    }

    @Test func acceptsPasswordsShorterThanSignUpMinimum() {
        let form = LoginForm(email: "name@example.com", password: "short")
        #expect(form.issue(for: .password) == nil)
    }
}
