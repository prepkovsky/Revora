import SwiftUI

struct ChangeNameView: View {
    private enum Field {
        case name
    }

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    private let currentName: String
    @State private var name: String
    @State private var isSubmitting = false
    @State private var submitError: AuthError?
    @FocusState private var focusedField: Field?

    init(currentName: String?) {
        self.currentName = currentName ?? ""
        _name = State(initialValue: currentName ?? "")
    }

    private var trimmedName: String {
        PersonName.trimmed(name)
    }

    private var nameIssue: String? {
        PersonName.issue(for: trimmedName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your name shows on your account, and Home greets you with your first name.")
                    .foregroundStyle(.secondary)

                FormField(
                    label: "Name",
                    hint: currentName.isEmpty ? nil : "Leave it empty to remove your name.",
                    error: nameIssue,
                    focus: $focusedField,
                    field: .name
                ) {
                    TextField("Name", text: $name, prompt: Text("Your name"))
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(save)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let submitError {
                        ErrorMessage(message: submitError.message)
                    }

                    Button(action: save) {
                        ProgressButtonLabel(title: "Save", isInProgress: isSubmitting)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .disabled(nameIssue != nil || trimmedName == currentName)
                }
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.appBackground)
        .onTapGesture { focusedField = nil }
        .navigationTitle(currentName.isEmpty ? "Add Your Name" : "Change Name")
        .navigationBarBackButtonHidden(isSubmitting)
        .onChange(of: name) {
            submitError = nil
        }
    }

    private func save() {
        guard nameIssue == nil, trimmedName != currentName, !isSubmitting else { return }

        focusedField = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do throws(AuthError) {
                try await authService.updateName(trimmedName)
                dismiss()
            } catch {
                submitError = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangeNameView(currentName: "Sam Taylor")
    }
    .environment(AuthService())
}
