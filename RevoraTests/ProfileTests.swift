import Foundation
import Testing
@testable import Revora

struct ProfileTests {
    @Test(arguments: [
        ("Patrik Repkovsky", "Patrik"),
        ("Sam", "Sam"),
        ("Mary  Jane Watson", "Mary"),
    ])
    func firstNameIsTheFirstWord(name: String, expected: String) {
        #expect(AuthUser(id: "uid", email: nil, name: name).firstName == expected)
    }

    @Test func noNameMeansNoFirstName() {
        #expect(AuthUser(id: "uid", email: "sam@example.com").firstName == nil)
    }

    @Test func nameIsOptionalButCapped() {
        #expect(PersonName.issue(for: "") == nil)
        #expect(PersonName.issue(for: String(repeating: "a", count: PersonName.maximumLength)) == nil)
        #expect(PersonName.issue(for: String(repeating: "a", count: PersonName.maximumLength + 1)) == PersonName.tooLong)
    }

    @Test func trimsWhitespaceAroundName() {
        #expect(PersonName.trimmed("  Sam Taylor \n") == "Sam Taylor")
    }

    @Test func registerFormAcceptsNoName() {
        let password = String(repeating: "a", count: AuthService.minimumPasswordLength)
        let form = RegisterForm(name: "  ", email: "sam@example.com", password: password, confirmPassword: password)
        #expect(form.trimmedName.isEmpty)
        #expect(form.isValid)
    }

    @Test func greetingAddsTheFirstName() {
        #expect(String(localized: Greeting.evening.title(firstName: "Sam")) == "Good evening, Sam")
        #expect(String(localized: Greeting.lateNight.title(firstName: "Sam")) == "Good evening, Sam")
        #expect(String(localized: Greeting.morning.title(firstName: nil)) == String(localized: Greeting.morning.title))
    }
}

struct ChangeEmailFormTests {
    private func validForm() -> ChangeEmailForm {
        ChangeEmailForm(currentEmail: "sam@example.com", newEmail: "sam.taylor@example.com", password: "password")
    }

    @Test func validFormHasNoIssues() {
        let form = validForm()
        #expect(form.isValid)
        for field in ChangeEmailForm.Field.allCases {
            #expect(form.issue(for: field) == nil)
        }
    }

    @Test(arguments: ["", "sam", "sam@example"])
    func rejectsInvalidEmails(_ email: String) {
        var form = validForm()
        form.newEmail = email
        #expect(form.issue(for: .newEmail) != nil)
        #expect(!form.isValid)
    }

    @Test(arguments: ["sam@example.com", " SAM@Example.com "])
    func newEmailMustDifferFromCurrent(_ email: String) {
        var form = validForm()
        form.newEmail = email
        #expect(form.issue(for: .newEmail) == "That's already your email.")
    }

    @Test func requiresPassword() {
        var form = validForm()
        form.password = ""
        #expect(form.issue(for: .password) != nil)
        #expect(!form.isValid)
    }
}
