import SwiftUI

struct RecipesView: View {
    @Environment(RecipeRepository.self) private var recipeRepository

    @State private var isShowingEditor = false

    var body: some View {
        content
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
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipeID: recipe.id)
            }
    }

    @ViewBuilder private var content: some View {
        if !recipeRepository.hasLoaded {
            DelayedProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if recipeRepository.recipes.isEmpty {
            ContentUnavailableView {
                Label("No Recipes Yet", systemImage: "book")
            } description: {
                Text("Recipes you create will show up here.")
            } actions: {
                Button("Create Your First Recipe") {
                    isShowingEditor = true
                }
                .buttonStyle(.primary)
            }
        } else {
            List(recipeRepository.recipes.sortedByTitle()) { recipe in
                NavigationLink(value: recipe) {
                    RecipeRowView(recipe: recipe)
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    NavigationStack {
        RecipesView()
    }
    .environment(RecipeRepository())
    .environment(RecipePhotoStore())
}
