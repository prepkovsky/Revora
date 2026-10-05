import Testing
@testable import Revora

struct AuthStateTests {
    private let user = AuthUser(id: "uid", email: "sam@example.com")

    @Test func confirmedEmailOpensTheApp() {
        #expect(AuthService.State(user: user, isEmailVerified: true) == .signedIn(user))
    }

    @Test func unconfirmedEmailWaitsForConfirmation() {
        #expect(AuthService.State(user: user, isEmailVerified: false) == .unverified(user))
    }

    @Test func noUserIsSignedOut() {
        #expect(AuthService.State(user: nil, isEmailVerified: true) == .signedOut)
    }

    @Test func onlySignedInStatesHaveASession() {
        #expect(AuthService.State.unverified(user).hasSession)
        #expect(AuthService.State.signedIn(user).hasSession)
        #expect(!AuthService.State.signedOut.hasSession)
        #expect(!AuthService.State.loading.hasSession)
    }
}
