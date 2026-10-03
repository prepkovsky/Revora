import FirebaseFirestore
import Foundation

/// Recipe failures the UI knows how to explain, so views never see raw Firestore errors.
enum RecipeError: Error, Equatable {
    case signedOut
    case offline
    case unknown

    init(_ error: any Error) {
        if let error = error as? PhotoError {
            switch error {
            case .offline: self = .offline
            case .signedOut: self = .signedOut
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
        default: self = .unknown
        }
    }

    var message: String {
        switch self {
        case .signedOut:
            "You're logged out. Log in and try again."
        case .offline:
            "You're offline. Check your connection and try again."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
