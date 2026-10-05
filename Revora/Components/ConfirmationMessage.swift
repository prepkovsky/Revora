import SwiftUI

/// What a form turns into once it's done: an icon, a title, what happens next, and a way on.
struct ConfirmationMessage: View {
    let systemImage: String
    let title: LocalizedStringResource
    let message: Text
    let buttonTitle: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondaryAccent)
                .accessibilityHidden(true)

            Text(title)
                .font(.display(.title2))
                .accessibilityAddTraits(.isHeader)

            message
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondaryText)

            Button(action: action) {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
}

#Preview {
    ConfirmationMessage(
        systemImage: "envelope.badge",
        title: "Check Your Email",
        message: Text("We sent you a link."),
        buttonTitle: "Done"
    ) {}
    .padding()
}
