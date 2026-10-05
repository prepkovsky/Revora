import FirebaseFirestore
import Foundation

/// Photo failures the UI knows how to explain, so views never see raw Firestore errors.
enum PhotoError: Error, Equatable {
    case unreadableImage
    case notFound
    case signedOut
    case offline
    case timedOut
    case quotaExceeded
    case unknown

    init(_ error: any Error) {
        if error is TimeoutError {
            self = .timedOut
            return
        }

        let error = error as NSError
        guard error.domain == FirestoreErrorDomain, let code = FirestoreErrorCode.Code(rawValue: error.code) else {
            self = .unknown
            return
        }

        switch code {
        case .unavailable: self = .offline
        case .notFound: self = .notFound
        // The free plan's daily and storage limits.
        case .resourceExhausted: self = .quotaExceeded
        case .unauthenticated: self = .signedOut
        default: self = .unknown
        }
    }

    var message: String {
        switch self {
        case .unreadableImage:
            "That photo can't be used. Try a different one."
        case .notFound:
            "This photo isn't available anymore."
        case .signedOut:
            "You're logged out. Log in and try again."
        case .offline:
            "You're offline. Check your connection and try again."
        case .timedOut:
            "This is taking too long. Check your connection and try again."
        case .quotaExceeded:
            "Revora has reached its photo storage limit for now. Try again later."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
