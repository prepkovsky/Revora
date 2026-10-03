import FirebaseAuth
import Foundation

/// Auth failures the UI knows how to explain, so views never see raw Firebase errors.
enum AuthError: Error, Equatable {
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case wrongCredentials
    /// Re-entering the password of the signed-in account, where only the password can be wrong.
    case wrongPassword
    case network
    case tooManyRequests
    case unknown

    init(_ error: any Error) {
        let error = error as NSError
        guard error.domain == AuthErrors.domain, let code = AuthErrorCode(rawValue: error.code) else {
            self = .unknown
            return
        }

        switch code {
        case .emailAlreadyInUse: self = .emailAlreadyInUse
        case .invalidEmail: self = .invalidEmail
        case .weakPassword: self = .weakPassword
        // With email enumeration protection on, Firebase reports all of these as invalidCredential.
        case .invalidCredential, .wrongPassword, .userNotFound: self = .wrongCredentials
        case .networkError: self = .network
        case .tooManyRequests: self = .tooManyRequests
        default: self = .unknown
        }
    }

    init(reauthenticating error: any Error) {
        let error = AuthError(error)
        self = error == .wrongCredentials ? .wrongPassword : error
    }

    var message: String {
        switch self {
        case .emailAlreadyInUse:
            "An account with this email already exists."
        case .invalidEmail:
            "Enter an email like name@example.com."
        case .weakPassword:
            "Choose a password with at least \(AuthService.minimumPasswordLength) characters."
        case .wrongCredentials:
            // Doesn't say which one is wrong, so it doesn't reveal whether an account exists.
            "That email and password don't match. Try again or reset your password."
        case .wrongPassword:
            "That password isn't right. Try again."
        case .network:
            "You're offline. Check your connection and try again."
        case .tooManyRequests:
            "Too many attempts. Wait a moment and try again."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
