import SwiftUI

struct ChangePasswordView: View {
    typealias Field = ChangePasswordForm.Field

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var form = ChangePasswordForm()
    @State private var checkedFields: Set<Field> = []
    @State private var isSubmitting = false
    @State private var submitError: AuthError?
    @State private var isChanged = false
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView {
            Group {
                if isChanged {
                    confirmation
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
        .navigationTitle("Change Password")
        .navigationBarBackButtonHidden(isSubmitting)
        .sensoryFeedback(.success, trigger: isChanged) { _, newValue in newValue }
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
            FormField(
                label: "Current Password",
                error: error(for: .currentPassword),
                focus: $focusedField,
                field: .currentPassword
            ) {
                PasswordField(title: "Current Password", text: $form.currentPassword)
                    .textContentType(.password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .newPassword }
            }

            FormField(
                label: "New Password",
                hint: RegisterForm.passwordRequirement,
                error: error(for: .newPassword),
                focus: $focusedField,
                field: .newPassword
            ) {
                PasswordField(title: "New Password", text: $form.newPassword)
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .confirmPassword }
            }

            FormField(
                label: "Confirm New Password",
                error: error(for: .confirmPassword),
                focus: $focusedField,
                field: .confirmPassword
            ) {
                PasswordField(title: "Confirm New Password", text: $form.confirmPassword)
                    .textContentType(.newPassword)
                    .submitLabel(.done)
                    .onSubmit(submit)
            }

            VStack(alignment: .leading, spacing: 12) {
                if let submitError, field(for: submitError) == nil {
                    ErrorMessage(message: submitError.message)
                }

                Button(action: submit) {
                    ProgressButtonLabel(title: "Change Password", isInProgress: isSubmitting)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(!form.isValid)
            }
        }
    }

    private var confirmation: some View {
        ConfirmationMessage(
            systemImage: "checkmark.shield",
            title: "Password Changed",
            message: Text("Use your new password the next time you log in."),
            buttonTitle: "Done"
        ) {
            dismiss()
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
        case .wrongPassword: .currentPassword
        case .weakPassword: .newPassword
        case .emailAlreadyInUse, .invalidEmail, .wrongCredentials, .network, .tooManyRequests, .unknown: nil
        }
    }

    private func isEmpty(_ field: Field) -> Bool {
        switch field {
        case .currentPassword: form.currentPassword.isEmpty
        case .newPassword: form.newPassword.isEmpty
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
                try await authService.changePassword(from: form.currentPassword, to: form.newPassword)
                withAnimation { isChanged = true }
                AccessibilityNotification.Announcement("Password changed.").post()
            } catch {
                submitError = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
    }
    .environment(AuthService())
}
