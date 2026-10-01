import SwiftUI

/// A recipe in a list, with its cover thumbnail or a placeholder, so titles line up.
struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            RecipePhotoView(recipe: recipe, size: .thumbnail)
                .frame(width: 56, height: 56)
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.title)
                    .font(.headline)
                summary
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
            ingredients: [Ingredient(name: "Flour", quantity: "200 g")],
            steps: ["Whisk everything together.", "Fry in a hot pan."],
            createdAt: .now,
            updatedAt: .now
        ))
        RecipeRowView(recipe: Recipe(id: "2", title: "Banana Bread", ingredients: [], steps: [], createdAt: .now, updatedAt: .now))
    }
    .environment(RecipePhotoStore())
}
