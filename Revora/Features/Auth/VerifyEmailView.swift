import SwiftUI

/// Stands in for the app until the account's email is confirmed, so recipes are only
/// ever tied to an address its owner can get back into.
struct VerifyEmailView: View {
    let email: String?

    @Environment(AuthService.self) private var authService

    @State private var isSending = false
    @State private var sendError: AuthError?
    @State private var resentCount = 0
    @State private var sentCount = 0
    @State private var emailWait: EmailRateLimit.Wait?
    @State private var logOutError: AuthError?

    private var displayEmail: String {
        email ?? String(localized: "your email")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondaryAccent)
                    .accessibilityHidden(true)

                Text("Confirm Your Email")
                    .font(.display(.title2))
                    .accessibilityAddTraits(.isHeader)

                Group {
                    if authService.isVerificationSent {
                        Text("We sent a link to \(displayEmail). Open it to confirm your email, and Revora carries on by itself. It can take a few minutes to arrive, so check your spam folder too.")
                    } else {
                        Text("Confirm \(displayEmail) to start using Revora. We'll send you a link to open.")
                    }
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondaryText)

                if authService.isVerificationSent {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Waiting for you to confirm")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondaryText)
                    .accessibilityElement(children: .combine)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let sendError {
                        ErrorMessage(message: sendError.message)
                    } else if let emailWait {
                        EmailWaitNote(wait: emailWait)
                    } else if resentCount > 0 {
                        Label("We sent a new link.", systemImage: "checkmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondaryText)
                    }

                    if authService.isVerificationSent {
                        Button(action: sendLink) {
                            Text("Send a New Link")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .fontWeight(.semibold)
                        .disabled(isSending || emailWait != nil)
                    } else {
                        Button(action: sendLink) {
                            ProgressButtonLabel(title: "Send Link", isInProgress: isSending)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.primary)
                        .disabled(emailWait != nil)
                    }
                }
                .padding(.top, 8)

                Button("Log Out", action: logOut)
                    .font(.subheadline)
                    .foregroundStyle(.secondaryText)
                    .frame(minHeight: 44)
            }
            .padding(.top, 24)
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .background(.appBackground)
        .navigationTitle("Confirm Email")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: resentCount)
        // Registering sent the first link, so this starts out waiting.
        .emailWait($emailWait, before: .verification, to: email ?? "", trigger: sentCount)
        // The link may be opened on another device, so the app never goes away and comes back.
        // Runs for as long as the screen shows, since there's no button to check by hand.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                await authService.checkEmailVerification()
            }
        }
        .alert(
            "Couldn't Log Out",
            isPresented: Binding { logOutError != nil } set: { if !$0 { logOutError = nil } },
            presenting: logOutError
        ) { _ in
            Button("Try Again", action: logOut)
            Button("Cancel", role: .cancel) {}
        } message: { error in
            Text(error.message)
        }
    }

    private func sendLink() {
        guard !isSending, emailWait == nil else { return }
        let wasSent = authService.isVerificationSent
        isSending = true
        sendError = nil
        Task {
            defer { isSending = false }
            do throws(AuthError) {
                try await authService.sendEmailVerification()
                sentCount += 1
                if wasSent {
                    resentCount += 1
                }
                AccessibilityNotification.Announcement("Link sent. Check your email.").post()
            } catch {
                sendError = error
            }
        }
    }

    private func logOut() {
        do throws(AuthError) {
            try authService.logOut()
        } catch {
            logOutError = error
        }
    }
}

#Preview {
    NavigationStack {
        VerifyEmailView(email: "name@example.com")
    }
    .environment(AuthService())
}
