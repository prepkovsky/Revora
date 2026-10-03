import SwiftUI

struct LoginView: View {
    typealias Field = LoginForm.Field

    @Environment(AuthService.self) private var authService

    @State private var form = LoginForm()
    @State private var checkedFields: Set<Field> = []
    @State private var isSubmitting = false
    @State private var submitError: AuthError?
    @State private var isResettingPassword = false
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let changedEmail = authService.changedEmail {
                    Label("Your email is now \(changedEmail). Log in with it to get back to your recipes.", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Welcome back. Log in to get to your recipes.")
                        .foregroundStyle(.secondary)
                }

                FormField(label: "Email", error: error(for: .email), focus: $focusedField, field: .email) {
                    TextField("Email", text: $form.email, prompt: Text("name@example.com"))
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }

                VStack(alignment: .trailing, spacing: 0) {
                    FormField(label: "Password", error: error(for: .password), focus: $focusedField, field: .password) {
                        PasswordField(title: "Password", text: $form.password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .onSubmit(submit)
                    }

                    Button("Forgot password?") {
                        isResettingPassword = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let submitError, field(for: submitError) == nil {
                        ErrorMessage(
                            message: submitError.message,
                            action: submitError == .wrongCredentials ? resetPassword : nil
                        )
                    }

                    Button(action: submit) {
                        ProgressButtonLabel(title: "Log In", isInProgress: isSubmitting)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .disabled(!form.isValid)
                }

                NavigationLink {
                    RegisterView { email in
                        form.email = email
                        form.password = ""
                    }
                } label: {
                    Text("New to Revora? \(Text("Create an account").fontWeight(.semibold).foregroundStyle(.tint))")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.rect)
                }
                // Keeps the link from tinting the whole line, so only the action stands out.
                .buttonStyle(.plain)
                .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.appBackground)
        .onTapGesture { focusedField = nil }
        .navigationTitle("Log In")
        .onAppear {
            if let changedEmail = authService.changedEmail, form.email.isEmpty {
                form.email = changedEmail
            }
        }
        .navigationDestination(isPresented: $isResettingPassword) {
            ResetPasswordView(email: form.trimmedEmail)
        }
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
        case .invalidEmail: .email
        case .emailAlreadyInUse, .weakPassword, .wrongCredentials, .wrongPassword, .network, .tooManyRequests, .unknown: nil
        }
    }

    private var resetPassword: RecoveryAction {
        RecoveryAction(title: "Reset Password") {
            isResettingPassword = true
        }
    }

    private func isEmpty(_ field: Field) -> Bool {
        switch field {
        case .email: form.email.isEmpty
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
                try await authService.logIn(email: form.trimmedEmail, password: form.password)
            } catch {
                submitError = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(AuthService())
}
