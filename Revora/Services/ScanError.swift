import FirebaseFunctions
import Foundation

/// Scan failures the UI knows how to explain, so views never see raw Firebase errors.
/// Most match an error code from the `scanRecipe` function.
enum ScanError: Error, Equatable {
    case unreadableImage
    case offline
    case timedOut
    case signedOut
    case emailNotConfirmed
    /// `resetsAt` is when scanning opens again, if the function said.
    case dailyLimitReached(resetsAt: Date?)
    /// Moderation turned the photo away.
    case photoNotAllowed
    case noRecipeFound
    /// OpenAI failed. The function doesn't count the scan.
    case unavailable
    case unknown

    init(_ error: any Error) {
        if let error = error as? PhotoError {
            self = error == .unreadableImage ? .unreadableImage : .unknown
            return
        }

        let error = error as NSError
        // Functions only turns a timeout into its own error. Other connection failures come through as they are.
        if error.domain == NSURLErrorDomain {
            switch URLError.Code(rawValue: error.code) {
            case .timedOut:
                self = .timedOut
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
                 .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff:
                self = .offline
            default:
                self = .unknown
            }
            return
        }

        guard error.domain == FunctionsErrorDomain, let code = FunctionsErrorCode(rawValue: error.code) else {
            self = .unknown
            return
        }

        switch code {
        case .unauthenticated: self = .signedOut
        case .permissionDenied: self = .emailNotConfirmed
        case .invalidArgument: self = .unreadableImage
        case .resourceExhausted: self = .dailyLimitReached(resetsAt: Self.resetDate(in: error.userInfo[FunctionsErrorDetailsKey]))
        case .failedPrecondition: self = .photoNotAllowed
        case .notFound: self = .noRecipeFound
        case .unavailable: self = .unavailable
        case .deadlineExceeded: self = .timedOut
        default: self = .unknown
        }
    }

    var message: String {
        switch self {
        case .unreadableImage:
            "This photo can't be read. Try a different one."
        case .offline:
            "You're offline. Scanning needs a connection, so try again once you're back online."
        case .timedOut:
            "This is taking too long. Check your connection and try again."
        case .signedOut:
            "You're logged out. Log in and try again."
        case .emailNotConfirmed:
            "Confirm your email to scan recipes."
        case .dailyLimitReached(let resetsAt):
            if let resetsAt, resetsAt > .now {
                "You've reached today's scan limit. You can scan again \(resetsAt.formatted(.relative(presentation: .numeric)))."
            } else {
                "You've reached today's scan limit. You can scan again tomorrow."
            }
        case .photoNotAllowed:
            "This photo can't be scanned. Try a photo of a recipe."
        case .noRecipeFound:
            "Revora couldn't find a recipe in this photo. Try a clear photo of a cookbook page or recipe card."
        case .unavailable:
            "Scanning isn't working right now. Try again in a moment."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }

    /// The function sends `{ resetsAt }` as an ISO 8601 date.
    private static func resetDate(in details: Any?) -> Date? {
        guard let resetsAt = (details as? [String: Any])?["resetsAt"] as? String else { return nil }
        return try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(resetsAt)
    }
}
