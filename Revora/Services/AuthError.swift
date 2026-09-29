import FirebaseAuth
import Foundation

/// Auth failures the UI knows how to explain, so views never see raw Firebase errors.
enum AuthError: Error, Equatable {
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
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
        case .networkError: self = .network
        case .tooManyRequests: self = .tooManyRequests
        default: self = .unknown
        }
    }

    var message: String {
        switch self {
        case .emailAlreadyInUse:
            "An account with this email already exists."
        case .invalidEmail:
            "Enter an email like name@example.com."
        case .weakPassword:
            "Choose a password with at least \(AuthService.minimumPasswordLength) characters."
        case .network:
            "You're offline. Check your connection and try again."
        case .tooManyRequests:
            "Too many attempts. Wait a moment and try again."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
