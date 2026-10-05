import SwiftUI

/// Stands in for the top of Home while recipes load: the two action tiles and the
/// Continue Cooking card, at their real sizes, so they take its place without a jump.
struct HomeSkeleton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = HomeActionTile.rowLayout(for: dynamicTypeSize)
        VStack(alignment: .leading, spacing: 28) {
            layout {
                tile
                tile
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: "Continue Cooking")
                    .font(.display(.title2))
                    .redacted(reason: .placeholder)
                card
            }
        }
        .shimmering()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading recipes")
    }

    /// A real tile, hidden, so the block is exactly its size at every text size.
    private var tile: some View {
        HomeActionTile(title: "New Recipe", subtitle: "Add one to your cookbook", systemImage: "plus")
            .hidden()
            .background(.fill, in: .rect(cornerRadius: 22))
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(.fill)
                .aspectRatio(16 / 10, contentMode: .fit)

            // Never shown as text: placeholder bars take the lines' size.
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "Spaghetti al Pomodoro")
                    .font(.display(.title2))
                Text(verbatim: "Opened 2 hours ago")
                    .font(.subheadline)
            }
            .redacted(reason: .placeholder)
            .padding(16)
        }
    }
}

#Preview {
    ScrollView {
        HomeSkeleton()
            .padding()
    }
    .background(.appBackground)
}
