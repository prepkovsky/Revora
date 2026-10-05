import FirebaseAuth
import Foundation
import Testing
@testable import Revora

struct AuthErrorTests {
    private func firebaseError(_ code: AuthErrorCode) -> NSError {
        NSError(domain: AuthErrors.domain, code: code.rawValue)
    }

    @Test(arguments: [
        (AuthErrorCode.emailAlreadyInUse, AuthError.emailAlreadyInUse),
        (.invalidEmail, .invalidEmail),
        (.weakPassword, .weakPassword),
        (.invalidCredential, .wrongCredentials),
        (.wrongPassword, .wrongCredentials),
        (.userNotFound, .wrongCredentials),
        (.networkError, .network),
        (.tooManyRequests, .tooManyRequests),
        (.internalError, .unknown),
    ])
    func mapsFirebaseCodes(code: AuthErrorCode, expected: AuthError) {
        #expect(AuthError(firebaseError(code)) == expected)
    }

    @Test(arguments: [AuthErrorCode.invalidCredential, .wrongPassword])
    func reauthenticatingBlamesOnlyThePassword(code: AuthErrorCode) {
        #expect(AuthError(reauthenticating: firebaseError(code)) == .wrongPassword)
    }

    @Test func reauthenticatingKeepsOtherErrors() {
        #expect(AuthError(reauthenticating: firebaseError(.tooManyRequests)) == .tooManyRequests)
        #expect(AuthError(reauthenticating: firebaseError(.networkError)) == .network)
    }

    @Test func mapsTimeouts() {
        #expect(AuthError(TimeoutError()) == .timedOut)
        #expect(AuthError(reauthenticating: TimeoutError()) == .timedOut)
    }

    @Test func treatsOtherDomainsAsUnknown() {
        let error = NSError(domain: NSURLErrorDomain, code: AuthErrorCode.emailAlreadyInUse.rawValue)
        #expect(AuthError(error) == .unknown)
    }

    @Test func weakPasswordMessageUsesMinimumLength() {
        #expect(AuthError.weakPassword.message.contains("\(AuthService.minimumPasswordLength)"))
    }
}
