import FirebaseAuth
import Observation
import os

struct AuthUser: Equatable {
    let id: String
    let email: String?
}

@Observable
final class AuthService {
    enum State: Equatable {
        case loading
        case signedOut
        case signedIn(AuthUser)
    }

    /// Stricter than Firebase's default of 6. Used for both validation and messages.
    nonisolated static let minimumPasswordLength = 8

    private static let logger = Logger(subsystem: "Revora", category: "Auth")

    private(set) var state: State = .loading

    /// Runs for as long as the calling task lives. The first value is the
    /// session Firebase restored from the keychain, which ends `.loading`.
    func observeAuthState() async {
        for await user in Auth.auth().authStateChanges {
            state = user.map { .signedIn(AuthUser(id: $0.uid, email: $0.email)) } ?? .signedOut
        }
    }

    /// Creating the account also signs in, so `state` follows through the listener.
    func register(email: String, password: String) async throws(AuthError) {
        do {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            Self.logger.error("Registration failed: \(error)")
            throw AuthError(error)
        }
    }
}
