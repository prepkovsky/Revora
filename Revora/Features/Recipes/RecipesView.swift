import SwiftUI

struct RecipesView: View {
    #if DEBUG
    @Environment(RecipeRepository.self) private var recipeRepository
    #endif

    @State private var isShowingEditor = false

    var body: some View {
        ContentUnavailableView {
            Label("Recipes", systemImage: "book")
        } actions: {
            #if DEBUG
            // Temporary, until the list replaces this placeholder.
            Text("\(recipeRepository.recipes.count) recipes")
            Button("Add Sample Recipe", action: addSampleRecipe)
            #endif
        }
        .background(.appBackground)
        .navigationTitle("Recipes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Recipe", systemImage: "plus") {
                    isShowingEditor = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            RecipeEditorView()
        }
    }

    #if DEBUG
    private func addSampleRecipe() {
        _ = try? recipeRepository.create(
            title: "Sample Pancakes",
            ingredients: [
                Ingredient(name: "Flour", quantity: "200 g"),
                Ingredient(name: "Milk", quantity: "300 ml"),
                Ingredient(name: "Eggs", quantity: "2"),
            ],
            steps: ["Whisk everything together.", "Fry in a hot pan."]
        )
    }
    #endif
}

#Preview {
    NavigationStack {
        RecipesView()
    }
    .environment(RecipeRepository())
}
