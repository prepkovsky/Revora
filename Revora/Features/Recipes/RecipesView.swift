import SwiftUI

struct RecipesView: View {
    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(RecipePhotoStore.self) private var photoStore
    @Environment(AppNavigation.self) private var navigation

    @State private var isShowingEditor = false
    @State private var scanSource: ScanPhotoSource?
    @State private var scanPhoto: ScanPhoto?
    @State private var recipeToDelete: Recipe?
    @State private var deleteError: RecipeError?
    @State private var favoriteError: RecipeError?
    @State private var searchText = ""
    /// Like a spinner, the skeleton waits a moment, so a quick load doesn't flash it.
    @State private var isSkeletonVisible = false
    @State private var listHeight = 0.0
    @ScaledMetric private var skeletonRowHeight = 72.0

    var body: some View {
        content
            .background(.appBackground)
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Add Recipe", systemImage: "plus") {
                        Button("New Recipe", systemImage: "square.and.pencil") {
                            isShowingEditor = true
                        }
                        Section("Scan a Recipe") {
                            if CameraPicker.isAvailable {
                                Button("Take Photo", systemImage: "camera") {
                                    scanSource = .camera
                                }
                            }
                            Button("Choose from Library", systemImage: "photo.on.rectangle") {
                                scanSource = .library
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                RecipeEditorView()
            }
            .scanPhotoPicker($scanSource) { scanPhoto = $0 }
            .sheet(item: $scanPhoto) { photo in
                ScanRecipeView(photo: photo)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipeID: recipe.id)
            }
            .recipeErrorAlert("Couldn't Delete Recipe", error: $deleteError)
            .recipeErrorAlert("Couldn't Update Favorites", error: $favoriteError)
            .task {
                try? await Task.sleep(for: .milliseconds(400))
                isSkeletonVisible = true
            }
    }

    @ViewBuilder private var content: some View {
        if let loadError = recipeRepository.loadError {
            RecipesLoadFailedView(error: loadError, retry: recipeRepository.retryLoading)
        } else if recipeRepository.hasLoaded && recipeRepository.recipes.isEmpty {
            ContentUnavailableView {
                EmptyStateLabel("No Recipes Yet", systemImage: "fork.knife")
            } description: {
                Text("Recipes you create will show up here.")
                    .foregroundStyle(.secondaryText)
            } actions: {
                Button("Create Your First Recipe") {
                    isShowingEditor = true
                }
                .buttonStyle(.primary)
            }
        } else {
            // The same list while loading, so the recipes replace the skeleton without a jump.
            recipeList(recipeRepository.hasLoaded ? navigation.recipeFilter.apply(
                to: recipeRepository.recipes,
                mealType: navigation.mealType,
                searchText: searchText
            ) : nil)
        }
    }

    /// `nil` while the recipes load.
    private func recipeList(_ recipes: [Recipe]?) -> some View {
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
            .listRowSeparator(.hidden)

            mealChips
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            Section {
                if let recipes {
                    recipeRows(recipes)
                } else if isSkeletonVisible {
                    // About as many as fit on screen. VoiceOver hears only the first.
                    ForEach(0..<max(Int(listHeight / skeletonRowHeight), 3), id: \.self) { index in
                        RecipeRowSkeleton(index: index)
                            .accessibilityHidden(index > 0)
                            .listRowBackground(Color.surface)
                    }
                }
            }
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .animation(.easeOut(duration: 0.25), value: isSkeletonVisible)
        .animation(.easeOut(duration: 0.25), value: recipes == nil)
        .onGeometryChange(for: Double.self) { $0.size.height } action: { listHeight = $0 }
        .overlay {
            if recipes?.isEmpty == true {
                emptyResult
            }
        }
        .searchable(text: $searchText, prompt: "Search Recipes")
    }

    private func recipeRows(_ recipes: [Recipe]) -> some View {
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

    /// One meal at a time. Tapping the picked one again shows every meal.
    private var mealChips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(MealType.allCases) { mealType in
                        MealTypeChip(mealType: mealType, isSelected: navigation.mealType == mealType) {
                            withAnimation(.snappy) {
                                navigation.mealType = navigation.mealType == mealType ? nil : mealType
                            }
                        }
                        .id(mealType)
                    }
                }
            }
            .scrollIndicators(.hidden)
            // Chips scroll out to the screen's edges instead of being cut off at the row's.
            .scrollClipDisabled()
            // Home can pick a meal whose chip is off screen, like Drink.
            .onChange(of: navigation.mealType, initial: true) {
                guard let mealType = navigation.mealType else { return }
                withAnimation(.snappy) {
                    proxy.scrollTo(mealType, anchor: .center)
                }
            }
        }
    }

    /// All is only empty when there are no recipes at all, which has its own screen.
    @ViewBuilder private var emptyResult: some View {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Not the built-in search state, whose description is in the system's paler gray.
            ContentUnavailableView {
                EmptyStateLabel("No Results for “\(searchText)”", systemImage: "magnifyingglass")
            } description: {
                Text("Check the spelling or try a new search.")
                    .foregroundStyle(.secondaryText)
            }
        } else if let mealType = navigation.mealType {
            let meal = String(localized: mealType.title)
            ContentUnavailableView {
                EmptyStateLabel("No \(meal) Recipes", systemImage: mealType.systemImage)
            } description: {
                Group {
                    switch navigation.recipeFilter {
                    case .recent: Text("You haven't opened a \(meal) recipe in the last \(RecipeFilter.recentDays) days.")
                    case .all: Text("Mark recipes as \(meal) when you edit them to see them here.")
                    case .favorites: Text("None of your favorites are marked \(meal).")
                    }
                }
                .foregroundStyle(.secondaryText)
            } actions: {
                Button("Show All Meals") {
                    withAnimation(.snappy) {
                        navigation.mealType = nil
                    }
                }
                .buttonStyle(.primary)
            }
        } else {
            switch navigation.recipeFilter {
            case .recent:
                ContentUnavailableView {
                    EmptyStateLabel("No Recent Recipes", systemImage: "clock")
                } description: {
                    Text("Recipes you open stay here for \(RecipeFilter.recentDays) days.")
                        .foregroundStyle(.secondaryText)
                }
            case .favorites:
                ContentUnavailableView {
                    EmptyStateLabel("No Favorites Yet", systemImage: "heart")
                } description: {
                    Text("Tap the heart on a recipe to see it here.")
                        .foregroundStyle(.secondaryText)
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
    .environment(RecipeScanner())
    .environment(Connectivity())
    .environment(AppNavigation())
}
