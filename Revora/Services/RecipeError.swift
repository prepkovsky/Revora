import FirebaseFirestore
import Foundation

/// Recipe failures the UI knows how to explain, so views never see raw Firestore errors.
enum RecipeError: Error, Equatable {
    case signedOut
    case offline
    case timedOut
    /// The free plan's daily limits, which are shared by everyone using the app.
    case quotaExceeded
    case unknown

    init(_ error: any Error) {
        if error is TimeoutError {
            self = .timedOut
            return
        }

        if let error = error as? PhotoError {
            switch error {
            case .offline: self = .offline
            case .timedOut: self = .timedOut
            case .signedOut: self = .signedOut
            case .quotaExceeded: self = .quotaExceeded
            default: self = .unknown
            }
            return
        }

        let error = error as NSError
        guard error.domain == FirestoreErrorDomain, let code = FirestoreErrorCode.Code(rawValue: error.code) else {
            self = .unknown
            return
        }

        switch code {
        case .unavailable: self = .offline
        case .unauthenticated: self = .signedOut
        case .resourceExhausted: self = .quotaExceeded
        default: self = .unknown
        }
    }

    var message: String {
        switch self {
        case .signedOut:
            "You're logged out. Log in and try again."
        case .offline:
            "You're offline. Check your connection and try again."
        case .timedOut:
            "This is taking too long. Check your connection and try again."
        case .quotaExceeded:
            "Revora has reached its limit for today. Your recipes are safe, so try again later."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
