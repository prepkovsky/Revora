import SwiftUI

struct RecipeDetailView: View {
    let recipeID: Recipe.ID

    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var titleHeight = 0.0
    @State private var isTitleInToolbar = false
    @ScaledMetric private var quantityWidth = 90.0

    /// At accessibility text sizes an amount column leaves the name too little room.
    private var stacksIngredients: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// Looked up live, so edits show up straight away.
    private var recipe: Recipe? {
        recipeRepository.recipes.first { $0.id == recipeID }
    }

    var body: some View {
        Group {
            if let recipe {
                content(for: recipe)
            } else {
                ContentUnavailableView(
                    "Recipe Not Found",
                    systemImage: "fork.knife",
                    description: Text("It may have been deleted.")
                )
            }
        }
        .background(.appBackground)
        .navigationTitle(recipe?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: recipeID) {
            guard let recipe else { return }
            try? recipeRepository.markOpened(recipe)
        }
    }

    private func content(for recipe: Recipe) -> some View {
        List {
            Text(recipe.title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
                .onGeometryChange(for: Double.self) { $0.size.height } action: { titleHeight = $0 }
                .listRowBackground(Color.clear)

            if !recipe.ingredients.isEmpty {
                Section("Ingredients") {
                    ForEach(recipe.ingredients.indices, id: \.self) { index in
                        let ingredient = recipe.ingredients[index]
                        let layout = stacksIngredients
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
                        layout {
                            if !(stacksIngredients && ingredient.quantity.isEmpty) {
                                Text(ingredient.quantity)
                                    .fontWeight(.semibold)
                                    .frame(width: stacksIngredients ? nil : quantityWidth, alignment: .leading)
                            }
                            Text(ingredient.name)
                        }
                    }
                }
                .listRowBackground(Color.surface)
            }

            if !recipe.steps.isEmpty {
                Section("Steps") {
                    ForEach(recipe.steps.indices, id: \.self) { index in
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(index + 1).")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text(recipe.steps[index])
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .listRowBackground(Color.surface)
            }

            if recipe.ingredients.isEmpty && recipe.steps.isEmpty {
                Text("This recipe doesn't have any ingredients or steps yet.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        // Like Contacts: the big title is part of the page, and a small one
        // fades into the bar once it has scrolled away.
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > titleHeight
        } action: { _, isScrolledPast in
            withAnimation(.easeOut(duration: 0.15)) {
                isTitleInToolbar = isScrolledPast
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(1)
                    .opacity(isTitleInToolbar ? 1 : 0)
                    .accessibilityHidden(!isTitleInToolbar)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipeID: "missing")
    }
    .environment(RecipeRepository())
}
