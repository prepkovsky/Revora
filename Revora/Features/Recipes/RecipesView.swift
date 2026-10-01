import SwiftUI

struct RecipesView: View {
    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(RecipePhotoStore.self) private var photoStore

    @State private var isShowingEditor = false
    @State private var recipeToDelete: Recipe?
    @State private var deleteError: RecipeError?

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
            .alert(
                "Couldn't Delete Recipe",
                isPresented: Binding { deleteError != nil } set: { if !$0 { deleteError = nil } },
                presenting: deleteError
            ) { _ in
                Button("OK") {}
            } message: { error in
                Text(error.message)
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
                // No full swipe, and a confirmation, because deleting can't be undone.
                // Not the destructive role: that slides the row out before anyone has confirmed.
                .swipeActions(allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash") {
                        recipeToDelete = recipe
                    }
                    .tint(.red)
                }
                // On each row, so the dialog points at the recipe it's about.
                .confirmationDialog(
                    "Delete \"\(recipe.title)\"?",
                    isPresented: Binding { recipeToDelete?.id == recipe.id } set: { if !$0 { recipeToDelete = nil } },
                    titleVisibility: .visible
                ) {
                    Button("Delete Recipe", role: .destructive) {
                        delete(recipe)
                    }
                } message: {
                    Text("This can't be undone.")
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func delete(_ recipe: Recipe) {
        do throws(RecipeError) {
            try recipeRepository.delete(recipe, photoStore: photoStore)
        } catch {
            deleteError = error
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
