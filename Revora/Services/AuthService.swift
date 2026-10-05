import FirebaseAuth
import Observation
import os

struct AuthUser: Equatable {
    let id: String
    let email: String?
    /// Optional, so older accounts and people who skipped it have none.
    var name: String?

    /// For a friendly greeting. Not every name puts the given name first,
    /// but people can change their name to whatever they'd like to be called.
    var firstName: String? {
        name?.split(whereSeparator: \.isWhitespace).first.map(String.init)
    }
}

@Observable
final class AuthService {
    enum State: Equatable {
        case loading
        case signedOut
        /// Signed in, but the email hasn't been confirmed yet, so the app stays closed.
        case unverified(AuthUser)
        case signedIn(AuthUser)

        nonisolated init(user: AuthUser?, isEmailVerified: Bool) {
            guard let user else {
                self = .signedOut
                return
            }
            self = isEmailVerified ? .signedIn(user) : .unverified(user)
        }

        var hasSession: Bool {
            switch self {
            case .loading, .signedOut: false
            case .unverified, .signedIn: true
            }
        }
    }

    /// Stricter than Firebase's default of 6. Used for both validation and messages.
    nonisolated static let minimumPasswordLength = 8

    private static let logger = Logger(subsystem: "Revora", category: "Auth")

    private(set) var state: State = .loading

    /// The address a requested email change is waiting on, until its link is opened.
    private(set) var pendingEmail: String?

    /// The new email, when the session ended because an email change went through,
    /// so Login can say why and fill it in. Cleared on the next sign-in.
    private(set) var changedEmail: String?

    /// Whether a confirmation link has gone out to the signed-in account, so the screen doesn't
    /// claim one was sent to accounts made before confirming was required. Kept across launches,
    /// so reopening the app doesn't offer a link that's already on its way.
    private(set) var isVerificationSent = false

    private let sentVerifications = SentVerifications()

    var currentUser: AuthUser? {
        guard case .signedIn(let user) = state else { return nil }
        return user
    }

    /// Runs for as long as the calling task lives. The first value is the
    /// session Firebase restored from the keychain, which ends `.loading`.
    func observeAuthState() async {
        for await user in Auth.auth().authStateChanges {
            if user == nil, let pendingEmail {
                // Logging out and deleting the account clear it first, so this is the link being opened.
                changedEmail = pendingEmail
            }
            if user != nil {
                changedEmail = nil
            } else {
                pendingEmail = nil
            }
            update(for: user)
        }
    }

    /// Creating the account also signs in, so `state` follows through the listener.
    /// An empty name is skipped.
    func register(name: String, email: String, password: String) async throws(AuthError) {
        do {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            Self.logger.error("Registration failed: \(error)")
            throw AuthError(error)
        }
        do throws(AuthError) {
            try await sendEmailVerification()
        } catch {
            // The account exists by now, and the confirm screen can send the link again.
            Self.logger.error("Sending the confirmation after registration failed: \(error)")
        }
        guard !name.isEmpty else { return }
        do throws(AuthError) {
            try await updateName(name)
        } catch {
            // The account exists by now, and the name can be added later in Account.
            Self.logger.error("Saving the name after registration failed: \(error)")
        }
    }

    /// An empty name removes it.
    func updateName(_ name: String) async throws(AuthError) {
        guard let user = Auth.auth().currentUser else { throw .unknown }
        let request = user.createProfileChangeRequest()
        request.displayName = name.isEmpty ? nil : name
        do {
            try await request.commitChanges()
        } catch {
            Self.logger.error("Updating the name failed: \(error)")
            throw AuthError(error)
        }
        refreshState()
    }

    /// Firebase emails a link to the new address and changes the email only once it's opened,
    /// so nobody can move an account to an address they don't own. Opening it also ends every
    /// session, so people log in again with the new email.
    func requestEmailChange(to newEmail: String, password: String) async throws(AuthError) {
        try await reauthenticate(password: password)
        guard let user = Auth.auth().currentUser else { throw .unknown }
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
            pendingEmail = newEmail
            Self.logger.info("Email change requested")
        } catch {
            Self.logger.error("Requesting an email change failed: \(error)")
            throw AuthError(error)
        }
    }

    /// Firebase's default handler page confirms the email when the link is opened, on any device.
    func sendEmailVerification() async throws(AuthError) {
        guard let user = Auth.auth().currentUser else { throw .unknown }
        do {
            try await user.sendEmailVerification()
            sentVerifications.insert(user.uid)
            isVerificationSent = true
            Self.logger.info("Email confirmation sent")
        } catch {
            Self.logger.error("Sending the email confirmation failed: \(error)")
            throw AuthError(error)
        }
    }

    /// Cheaper than `refreshUser`, so it can run every few seconds while the confirm screen waits.
    /// The session only gets a new token once the email is confirmed, and before `state` opens the
    /// app, so the recipe listener never starts with a token the security rules would reject.
    func checkEmailVerification() async {
        guard let user = Auth.auth().currentUser, !user.isEmailVerified else { return }
        do {
            try await user.reload()
            guard user.isEmailVerified else { return }
            _ = try await user.getIDTokenResult(forcingRefresh: true)
            Self.logger.info("Email confirmed")
            refreshState()
        } catch {
            Self.logger.info("Checking the email confirmation failed: \(error)")
        }
    }

    /// Picks up changes made outside the app, like an email confirmed from its link.
    /// Confirming it ends every session, but Firebase only notices when it next refreshes the
    /// session, up to an hour later. Forcing that refresh now makes it sign out straight away,
    /// and `state` follows through the listener. The new token also carries a newly confirmed
    /// email, which the security rules check.
    func refreshUser() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            _ = try await user.getIDTokenResult(forcingRefresh: true)
            try await user.reload()
            refreshState()
        } catch {
            Self.logger.info("Refreshing the user failed: \(error)")
        }
    }

    func logIn(email: String, password: String) async throws(AuthError) {
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            Self.logger.error("Log in failed: \(error)")
            throw AuthError(error)
        }
    }

    /// Firebase only emails addresses that have an account, but this succeeds either way
    /// so the screen can't be used to find out which emails have accounts.
    func sendPasswordReset(email: String) async throws(AuthError) {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            Self.logger.info("Password reset requested")
        } catch let error as NSError
            where error.domain == AuthErrors.domain && error.code == AuthErrorCode.userNotFound.rawValue {
            Self.logger.info("Password reset skipped: no account for that email")
        } catch {
            Self.logger.error("Password reset failed: \(error)")
            throw AuthError(error)
        }
    }

    /// Firebase only deletes an account that signed in recently, so asking for the
    /// password again both confirms it's really them and makes the deletion allowed.
    func reauthenticate(password: String) async throws(AuthError) {
        guard let user = Auth.auth().currentUser, let email = user.email else { throw .unknown }
        do {
            _ = try await user.reauthenticate(with: EmailAuthProvider.credential(withEmail: email, password: password))
        } catch {
            Self.logger.error("Re-authentication failed: \(error)")
            throw AuthError(reauthenticating: error)
        }
    }

    /// Firebase only changes the password after a recent sign-in, so the current one is
    /// checked first. The account stays signed in on this device afterwards.
    func changePassword(from currentPassword: String, to newPassword: String) async throws(AuthError) {
        try await reauthenticate(password: currentPassword)
        guard let user = Auth.auth().currentUser else { throw .unknown }
        do {
            try await user.updatePassword(to: newPassword)
            Self.logger.info("Password changed")
        } catch {
            Self.logger.error("Changing the password failed: \(error)")
            throw AuthError(error)
        }
    }

    /// Deleting the account also signs out, so `state` follows through the listener.
    func deleteAccount() async throws(AuthError) {
        guard let user = Auth.auth().currentUser else { throw .unknown }
        pendingEmail = nil
        do {
            try await user.delete()
            Self.logger.info("Account deleted")
        } catch {
            Self.logger.error("Deleting the account failed: \(error)")
            throw AuthError(error)
        }
    }

    /// Profile changes don't go through the auth state listener.
    private func refreshState() {
        guard let user = Auth.auth().currentUser else { return }
        if let pendingEmail, user.email?.caseInsensitiveCompare(pendingEmail) == .orderedSame {
            self.pendingEmail = nil
        }
        update(for: user)
    }

    private func update(for user: User?) {
        if let user, user.isEmailVerified {
            sentVerifications.remove(user.uid)
        }
        isVerificationSent = user.map { sentVerifications.contains($0.uid) } ?? false
        state = State(user: user.map(Self.authUser(from:)), isEmailVerified: user?.isEmailVerified ?? false)
    }

    private static func authUser(from user: User) -> AuthUser {
        let name = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return AuthUser(id: user.uid, email: user.email, name: name?.isEmpty == false ? name : nil)
    }

    func logOut() throws(AuthError) {
        pendingEmail = nil
        do {
            try Auth.auth().signOut()
        } catch {
            Self.logger.error("Log out failed: \(error)")
            throw AuthError(error)
        }
    }
}
