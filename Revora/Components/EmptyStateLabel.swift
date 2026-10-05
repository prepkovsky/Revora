import SwiftUI

/// An empty state's title in the display face, with its symbol in the app's secondary text
/// color. `ContentUnavailableView` sets its own fonts and colors, but ones set here win.
struct EmptyStateLabel: View {
    let title: LocalizedStringResource
    let systemImage: String

    init(_ title: LocalizedStringResource, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(title)
                .font(.display(.title2))
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondaryText)
        }
    }
}

#Preview {
    ContentUnavailableView {
        EmptyStateLabel("No Recipes Yet", systemImage: "fork.knife")
    } description: {
        Text("Recipes you create will show up here.")
            .foregroundStyle(.secondaryText)
    }
    .background(.appBackground)
}
