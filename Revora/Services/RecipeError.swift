import Foundation

/// Recipe failures the UI knows how to explain, so views never see raw Firestore errors.
enum RecipeError: Error, Equatable {
    case signedOut
    case unknown

    var message: String {
        switch self {
        case .signedOut:
            "You're logged out. Log in and try again."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
