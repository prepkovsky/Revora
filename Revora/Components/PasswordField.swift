import SwiftUI

/// A secure field with a button to show the password, so people can check what they typed.
struct PasswordField: View {
    private enum Input {
        case secure, plain
    }

    let title: String
    @Binding var text: String

    @State private var isRevealed = false
    @FocusState private var focusedInput: Input?

    private var visibleInput: Input {
        isRevealed ? .plain : .secure
    }

    var body: some View {
        HStack(spacing: 8) {
            // Both fields stay in place so showing the password hands focus from one to the
            // other. Swapping them out, or disabling the focused one, would dismiss the keyboard.
            ZStack {
                SecureField(title, text: $text)
                    .focused($focusedInput, equals: .secure)
                    .hiddenInput(isRevealed)

                TextField(title, text: $text)
                    .focused($focusedInput, equals: .plain)
                    .hiddenInput(!isRevealed)
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button(
                isRevealed ? "Hide Password" : "Show Password",
                systemImage: isRevealed ? "eye.slash" : "eye"
            ) {
                isRevealed.toggle()
                guard focusedInput != nil else { return }
                // iOS clears a secure field on the first keystroke after it gains focus, so
                // continuing to type after hiding would erase the password. End editing instead.
                focusedInput = isRevealed ? .plain : nil
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(.secondary)
        }
        .onChange(of: focusedInput) {
            // Focus set on the whole field from outside can land on the hidden input.
            if let focusedInput, focusedInput != visibleInput {
                self.focusedInput = visibleInput
            }
        }
    }
}

private extension View {
    func hiddenInput(_ isHidden: Bool) -> some View {
        opacity(isHidden ? 0 : 1)
            .allowsHitTesting(!isHidden)
            .accessibilityHidden(isHidden)
    }
}

#Preview {
    @Previewable @State var password = "hunter22"

    PasswordField(title: "Password", text: $password)
        .padding()
}
