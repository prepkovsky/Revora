import SwiftUI

struct ChangeEmailView: View {
    typealias Field = ChangeEmailForm.Field

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var form: ChangeEmailForm
    @State private var checkedFields: Set<Field> = []
    @State private var isSubmitting = false
    @State private var submitError: AuthError?
    @State private var sentToEmail: String?
    @FocusState private var focusedField: Field?

    init(currentEmail: String?) {
        _form = State(initialValue: ChangeEmailForm(currentEmail: currentEmail))
    }

    var body: some View {
        ScrollView {
            Group {
                if let sentToEmail {
                    ConfirmationMessage(
                        systemImage: "envelope.badge",
                        title: "Check Your Inbox",
                        message: Text("We sent a link to \(sentToEmail). Open it to finish changing your email, then log in again with your new email. It can take a few minutes, so check your spam folder too."),
                        buttonTitle: "Done"
                    ) {
                        dismiss()
                    }
                } else {
                    formContent
                }
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.appBackground)
        .onTapGesture { focusedField = nil }
        .navigationTitle("Change Email")
        .navigationBarBackButtonHidden(isSubmitting)
        .sensoryFeedback(.success, trigger: sentToEmail) { _, newValue in newValue != nil }
        .onChange(of: focusedField) { oldField, _ in
            // Only judge a field once people leave it, not while they're still typing.
            if let oldField, !isEmpty(oldField) {
                checkedFields.insert(oldField)
            }
        }
        .onChange(of: form) {
            submitError = nil
        }
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("We'll send a link to your new email to check that it's yours. Your email changes once you open it, and then you log in again with the new one.")
                .foregroundStyle(.secondary)

            FormField(
                label: "New Email",
                error: error(for: .newEmail),
                focus: $focusedField,
                field: .newEmail
            ) {
                TextField("New Email", text: $form.newEmail, prompt: Text("name@example.com"))
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            FormField(
                label: "Password",
                hint: "Enter your password to confirm it's you.",
                error: error(for: .password),
                focus: $focusedField,
                field: .password
            ) {
                PasswordField(title: "Password", text: $form.password)
                    .textContentType(.password)
                    .submitLabel(.send)
                    .onSubmit(submit)
            }

            VStack(alignment: .leading, spacing: 12) {
                if let submitError, field(for: submitError) == nil {
                    ErrorMessage(message: submitError.message)
                }

                Button(action: submit) {
                    ProgressButtonLabel(title: "Send Confirmation Link", isInProgress: isSubmitting)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(!form.isValid)
            }
        }
    }

    private func error(for field: Field) -> String? {
        if let submitError, self.field(for: submitError) == field {
            return submitError.message
        }
        return checkedFields.contains(field) ? form.issue(for: field) : nil
    }

    /// The field a server-side error belongs under, or `nil` to show it by the button.
    private func field(for error: AuthError) -> Field? {
        switch error {
        case .invalidEmail, .emailAlreadyInUse: .newEmail
        case .wrongPassword: .password
        case .weakPassword, .wrongCredentials, .network, .timedOut, .tooManyRequests, .unknown: nil
        }
    }

    private func isEmpty(_ field: Field) -> Bool {
        switch field {
        case .newEmail: form.newEmail.isEmpty
        case .password: form.password.isEmpty
        }
    }

    private func submit() {
        guard form.isValid else {
            checkedFields = Set(Field.allCases)
            return
        }
        guard !isSubmitting else { return }

        focusedField = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do throws(AuthError) {
                try await authService.requestEmailChange(to: form.trimmedEmail, password: form.password)
                withAnimation { sentToEmail = form.trimmedEmail }
                AccessibilityNotification.Announcement("Confirmation link sent. Check your new email.").post()
            } catch {
                submitError = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangeEmailView(currentEmail: "name@example.com")
    }
    .environment(AuthService())
}
