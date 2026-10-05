import SwiftUI

/// A recipe in a list, with its cover thumbnail or a placeholder, so titles line up.
struct RecipeRowView: View {
    let recipe: Recipe

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // The text needs the whole width, so the photo and heart go above it.
                VStack(alignment: .leading, spacing: 8) {
                    thumbnail
                    details
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // An overlay, so VoiceOver still reads the title first.
                .overlay(alignment: .topTrailing) {
                    favoriteMark
                        .frame(height: 56)
                }
            } else {
                HStack(spacing: 12) {
                    thumbnail
                    details
                    if recipe.isFavorite {
                        Spacer()
                        favoriteMark
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var thumbnail: some View {
        RecipePhotoView(recipe: recipe, size: .thumbnail)
            .frame(width: 56, height: 56)
            .clipShape(.rect(cornerRadius: 10))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(recipe.title)
                .font(.headline)
            summary
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
        }
    }

    @ViewBuilder private var favoriteMark: some View {
        if recipe.isFavorite {
            Image(systemName: "heart.fill")
                .font(.subheadline)
                .foregroundStyle(.tint)
                .accessibilityLabel("Favorite")
        }
    }

    @ViewBuilder private var summary: some View {
        let ingredients = Text("^[\(recipe.ingredients.count) ingredient](inflect: true)")
        let steps = Text("^[\(recipe.steps.count) step](inflect: true)")
        switch (recipe.ingredients.isEmpty, recipe.steps.isEmpty) {
        case (false, false): Text("\(ingredients) · \(steps)")
        case (false, true): ingredients
        case (true, false): steps
        case (true, true): EmptyView()
        }
    }
}

#Preview {
    List {
        RecipeRowView(recipe: Recipe(
            id: "1",
            title: "Pancakes",
            ingredientSections: RecipeSection.untitled([Ingredient(name: "Flour", quantity: "200 g")]),
            stepSections: RecipeSection.untitled([Step(text: "Whisk everything together."), Step(text: "Fry in a hot pan.")]),
            createdAt: .now,
            updatedAt: .now
        ))
        RecipeRowView(recipe: Recipe(id: "2", title: "Banana Bread", isFavorite: true, createdAt: .now, updatedAt: .now))
    }
    .environment(RecipePhotoStore())
    .environment(Connectivity())
}
