import SwiftUI

extension View {
    /// A quiet "Offline" badge in the navigation bar. Offline isn't an error, since recipes
    /// keep working, so it doesn't interrupt. Tapping it explains what still works.
    func offlineIndicator() -> some View {
        modifier(OfflineIndicator())
    }
}

private struct OfflineIndicator: ViewModifier {
    @Environment(Connectivity.self) private var connectivity

    @State private var isExplaining = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                if !connectivity.isOnline {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isExplaining = true
                        } label: {
                            // Not a Label: the bar would show only its icon, which is less clear.
                            HStack(spacing: 6) {
                                Image(systemName: "icloud.slash")
                                Text("Offline")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        }
                        .accessibilityHint("Explains what works without a connection")
                        .popover(isPresented: $isExplaining) {
                            Text("You're offline. Your recipes are still here, and changes you make sync once you're back online.")
                                .frame(width: 260)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding()
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                }
            }
    }
}
