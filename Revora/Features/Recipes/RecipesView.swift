import SwiftUI

struct RecipesView: View {
    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(RecipePhotoStore.self) private var photoStore
    @Environment(AppNavigation.self) private var navigation

    @State private var isShowingEditor = false
    @State private var recipeToDelete: Recipe?
    @State private var deleteError: RecipeError?
    @State private var favoriteError: RecipeError?
    @State private var searchText = ""

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
            .recipeErrorAlert("Couldn't Delete Recipe", error: $deleteError)
            .recipeErrorAlert("Couldn't Update Favorites", error: $favoriteError)
    }

    @ViewBuilder private var content: some View {
        if !recipeRepository.hasLoaded {
            DelayedProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if recipeRepository.recipes.isEmpty {
            ContentUnavailableView {
                Label(displayTitle: "No Recipes Yet", systemImage: "book")
            } description: {
                Text("Recipes you create will show up here.")
            } actions: {
                Button("Create Your First Recipe") {
                    isShowingEditor = true
                }
                .buttonStyle(.primary)
            }
        } else {
            recipeList(navigation.recipeFilter.apply(to: recipeRepository.recipes, searchText: searchText))
        }
    }

    private func recipeList(_ recipes: [Recipe]) -> some View {
        @Bindable var navigation = navigation
        return List {
            // In the list rather than pinned under the bar, so the search field
            // can slide out above it without the two overlapping.
            Picker("Show", selection: $navigation.recipeFilter) {
                ForEach(RecipeFilter.allCases) { filter in
                    Text(filter.title)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section {
                ForEach(recipes) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeRowView(recipe: recipe)
                    }
                    // A full swipe is fine here: it's undone by swiping again.
                    .swipeActions(edge: .leading) {
                        Button(
                            recipe.isFavorite ? "Unfavorite" : "Favorite",
                            systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                        ) {
                            setFavorite(!recipe.isFavorite, for: recipe)
                        }
                        .tint(.secondaryAccent)
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
            }
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .overlay {
            if recipes.isEmpty {
                emptyResult
            }
        }
        .searchable(text: $searchText, prompt: "Search Recipes")
    }

    /// All is only empty when there are no recipes at all, which has its own screen.
    @ViewBuilder private var emptyResult: some View {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            switch navigation.recipeFilter {
            case .recent:
                ContentUnavailableView {
                    Label(displayTitle: "No Recent Recipes", systemImage: "clock")
                } description: {
                    Text("Recipes you open stay here for \(RecipeFilter.recentDays) days.")
                }
            case .favorites:
                ContentUnavailableView {
                    Label(displayTitle: "No Favorites Yet", systemImage: "heart")
                } description: {
                    Text("Tap the heart on a recipe to see it here.")
                }
            case .all:
                EmptyView()
            }
        }
    }

    private func setFavorite(_ isFavorite: Bool, for recipe: Recipe) {
        do throws(RecipeError) {
            try recipeRepository.setFavorite(isFavorite, for: recipe)
        } catch {
            favoriteError = error
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
    .environment(AppNavigation())
}
