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

    @Test func treatsOtherDomainsAsUnknown() {
        let error = NSError(domain: NSURLErrorDomain, code: AuthErrorCode.emailAlreadyInUse.rawValue)
        #expect(AuthError(error) == .unknown)
    }

    @Test func weakPasswordMessageUsesMinimumLength() {
        #expect(AuthError.weakPassword.message.contains("\(AuthService.minimumPasswordLength)"))
    }
}
