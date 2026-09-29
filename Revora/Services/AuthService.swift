import FirebaseAuth
import Observation

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

    private(set) var state: State = .loading

    /// Runs for as long as the calling task lives. The first value is the
    /// session Firebase restored from the keychain, which ends `.loading`.
    func observeAuthState() async {
        for await user in Auth.auth().authStateChanges {
            state = user.map { .signedIn(AuthUser(id: $0.uid, email: $0.email)) } ?? .signedOut
        }
    }
}
