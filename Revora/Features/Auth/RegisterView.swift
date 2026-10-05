import SwiftUI

struct RegisterView: View {
    typealias Field = RegisterForm.Field

    /// Goes back to Login with the email filled in.
    let onLogIn: (_ email: String) -> Void

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var form = RegisterForm()
    @State private var checkedFields: Set<Field> = []
    @State private var isSubmitting = false
    @State private var submitError: AuthError?
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Create an account to keep your recipes synced and safe.")
                    .foregroundStyle(.secondary)

                FormField(
                    label: "Name",
                    hint: "Optional. Home greets you with your first name.",
                    error: error(for: .name),
                    focus: $focusedField,
                    field: .name
                ) {
                    TextField("Name", text: $form.name, prompt: Text("Your name"))
                        .accessibilityLabel("Name")
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                }

                FormField(
                    label: "Email",
                    error: error(for: .email),
                    errorAction: submitError == .emailAlreadyInUse ? logInInstead : nil,
                    focus: $focusedField,
                    field: .email
                ) {
                    TextField("Email", text: $form.email, prompt: Text(verbatim: "name@example.com"))
                        .accessibilityLabel("Email")
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }

                FormField(
                    label: "Password",
                    hint: RegisterForm.passwordRequirement,
                    error: error(for: .password),
                    focus: $focusedField,
                    field: .password
                ) {
                    PasswordField(title: "Password", text: $form.password)
                        .textContentType(.newPassword)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                }

                FormField(
                    label: "Confirm Password",
                    error: error(for: .confirmPassword),
                    focus: $focusedField,
                    field: .confirmPassword
                ) {
                    PasswordField(title: "Confirm Password", text: $form.confirmPassword)
                        .textContentType(.newPassword)
                        .submitLabel(.join)
                        .onSubmit(submit)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let submitError, field(for: submitError) == nil {
                        ErrorMessage(message: submitError.message)
                    }

                    Button(action: submit) {
                        ProgressButtonLabel(title: "Create Account", isInProgress: isSubmitting)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .disabled(!form.isValid)
                }
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.appBackground)
        .onTapGesture { focusedField = nil }
        .navigationTitle("Create Account")
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

    private func error(for field: Field) -> String? {
        if let submitError, self.field(for: submitError) == field {
            return submitError.message
        }
        return checkedFields.contains(field) ? form.issue(for: field) : nil
    }

    /// The field a server-side error belongs under, or `nil` to show it by the button.
    private func field(for error: AuthError) -> Field? {
        switch error {
        case .emailAlreadyInUse, .invalidEmail: .email
        case .weakPassword: .password
        case .wrongCredentials, .wrongPassword, .network, .timedOut, .tooManyRequests, .unknown: nil
        }
    }

    private var logInInstead: RecoveryAction {
        RecoveryAction(title: "Log In Instead") {
            onLogIn(form.trimmedEmail)
            dismiss()
        }
    }

    private func isEmpty(_ field: Field) -> Bool {
        switch field {
        case .name: form.name.isEmpty
        case .email: form.email.isEmpty
        case .password: form.password.isEmpty
        case .confirmPassword: form.confirmPassword.isEmpty
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
                try await authService.register(name: form.trimmedName, email: form.trimmedEmail, password: form.password)
            } catch {
                submitError = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView { _ in }
    }
    .environment(AuthService())
}
