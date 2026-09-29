import SwiftUI

/// The filled button for a screen's main action. The system style always labels it in
/// white, which is unreadable on the Almond accent in dark mode, so the label uses
/// AccentForeground instead. Disabled buttons keep the system's gray label.
struct PrimaryButtonStyle: PrimitiveButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .fontWeight(.semibold)
            .foregroundStyle(isEnabled ? AnyShapeStyle(.accentForeground) : AnyShapeStyle(.tertiary))
    }
}

extension PrimitiveButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

#Preview {
    VStack(spacing: 16) {
        Button {} label: {
            Text("Log In")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)

        Button {} label: {
            Text("Log In")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .disabled(true)
    }
    .padding()
}
