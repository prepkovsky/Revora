import SwiftUI

/// An inline error. The icon keeps it from relying on color alone, and the optional
/// action gives people a way forward.
struct ErrorMessage: View {
    let message: String
    var action: RecoveryAction?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(message, systemImage: "exclamationmark.circle")
                .font(.footnote)
                .foregroundStyle(.red)

            if let action {
                Button(action.title, action: action.perform)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

struct RecoveryAction {
    let title: String
    let perform: () -> Void
}

#Preview {
    ErrorMessage(
        message: "That email and password don't match. Try again or reset your password.",
        action: RecoveryAction(title: "Reset Password") {}
    )
    .padding()
}
