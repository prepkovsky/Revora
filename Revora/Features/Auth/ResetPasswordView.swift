import SwiftUI

struct ResetPasswordView: View {
    private enum Field {
        case email
    }

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var isEmailChecked = false
    @State private var isSubmitting = false
    @State private var submitError: AuthError?
    @State private var sentToEmail: String?
    @FocusState private var focusedField: Field?

    init(email: String = "") {
        _email = State(initialValue: email)
    }

    private var trimmedEmail: String {
        EmailAddress.trimmed(email)
    }

    private var emailIssue: String? {
        EmailAddress.issue(for: trimmedEmail)
    }

    private var emailError: String? {
        if submitError == .invalidEmail {
            return AuthError.invalidEmail.message
        }
        return isEmailChecked ? emailIssue : nil
    }

    var body: some View {
        ScrollView {
            Group {
                if let sentToEmail {
                    confirmation(for: sentToEmail)
                } else {
                    form
                }
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.appBackground)
        .onTapGesture { focusedField = nil }
        .navigationTitle("Reset Password")
        .sensoryFeedback(.success, trigger: sentToEmail) { _, newValue in newValue != nil }
        .onChange(of: focusedField) { oldField, _ in
            // Only judge the email once people leave the field, not while they're still typing.
            if oldField == .email, !email.isEmpty {
                isEmailChecked = true
            }
        }
        .onChange(of: email) {
            submitError = nil
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Enter the email you use for Revora, and we'll send you a link to reset your password.")
                .foregroundStyle(.secondary)

            FormField(label: "Email", error: emailError, focus: $focusedField, field: .email) {
                TextField("Email", text: $email, prompt: Text("name@example.com"))
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit(submit)
            }

            VStack(alignment: .leading, spacing: 12) {
                if let submitError, submitError != .invalidEmail {
                    ErrorMessage(message: submitError.message)
                }

                Button(action: submit) {
                    ProgressButtonLabel(title: "Send Reset Link", isInProgress: isSubmitting)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(emailIssue != nil)
            }
        }
    }

    private func confirmation(for email: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundStyle(.secondaryAccent)
                .accessibilityHidden(true)

            Text("Check Your Email")
                .font(.title2.bold())

            Text("If there's an account for \(email), you'll get a link to reset your password. It can take a few minutes, so check your spam folder too.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                dismiss()
            } label: {
                Text("Back to Log In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func submit() {
        guard emailIssue == nil else {
            isEmailChecked = true
            return
        }
        guard !isSubmitting else { return }

        focusedField = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do throws(AuthError) {
                try await authService.sendPasswordReset(email: trimmedEmail)
                withAnimation { sentToEmail = trimmedEmail }
                AccessibilityNotification.Announcement("Reset link sent. Check your email.").post()
            } catch {
                submitError = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(email: "name@example.com")
    }
    .environment(AuthService())
}
