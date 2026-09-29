import SwiftUI

/// A text input with its label above it and a hint or error below it.
/// The label stays visible, unlike placeholder text, which disappears as people type.
/// The input should carry the same label for VoiceOver, so the visible one is hidden from it.
struct FormField<Field: Hashable, Input: View>: View {
    let label: String
    var hint: String?
    var error: String?
    /// A way to recover from the error, shown under it.
    var errorAction: RecoveryAction?
    let focus: FocusState<Field?>.Binding
    let field: Field
    @ViewBuilder let input: Input

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .accessibilityHidden(true)

            input
                .focused(focus, equals: field)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
                .overlay {
                    if error != nil {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.red)
                    }
                }
                // The input only covers its own line of text, so taps on the padding would miss it.
                .contentShape(.rect)
                .onTapGesture { focus.wrappedValue = field }

            if let error {
                ErrorMessage(message: error, action: errorAction)
            } else if let hint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @FocusState var focusedField: Int?

    VStack(spacing: 24) {
        FormField(
            label: "Email",
            error: "An account with this email already exists.",
            errorAction: RecoveryAction(title: "Log In Instead") {},
            focus: $focusedField,
            field: 0
        ) {
            TextField("Email", text: .constant("name@"), prompt: Text("name@example.com"))
        }
        FormField(label: "Password", hint: "Use at least 8 characters.", focus: $focusedField, field: 1) {
            PasswordField(title: "Password", text: .constant(""))
        }
    }
    .padding()
}
