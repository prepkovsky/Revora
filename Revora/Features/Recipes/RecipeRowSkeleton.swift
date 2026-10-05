import SwiftUI

/// Stands in for a `RecipeRowView` while recipes load, at the same size, so the recipes
/// take its place without the list jumping.
struct RecipeRowSkeleton: View {
    /// Varies the bars' lengths from row to row, like real titles.
    let index: Int

    private static let titles = ["Lemon herb chicken", "Banana bread", "Roasted tomato soup", "Pancakes", "Spinach and feta pie"]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Laid out like the row: the photo goes above the text at accessibility text sizes.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            RoundedRectangle(cornerRadius: 10)
                .fill(.fill)
                .frame(width: 56, height: 56)

            // Never shown as text: placeholder bars take the lines' size.
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: Self.titles[index % Self.titles.count])
                    .font(.headline)
                Text(verbatim: "6 ingredients · 4 steps")
                    .font(.subheadline)
            }
            .redacted(reason: .placeholder)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shimmering()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading recipes")
    }
}

#Preview {
    List(0..<6, id: \.self) { index in
        RecipeRowSkeleton(index: index)
    }
}
