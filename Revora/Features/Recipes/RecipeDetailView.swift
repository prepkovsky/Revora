import SwiftUI

struct RecipeDetailView: View {
    let recipeID: Recipe.ID

    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(RecipePhotoStore.self) private var photoStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var deleteError: RecipeError?
    @State private var favoriteError: RecipeError?
    /// Kept on screen while the view goes away, instead of "Recipe Not Found".
    @State private var deletedRecipe: Recipe?

    /// Where the big title ends, and where the navigation bar ends, both in the scroll view.
    @State private var titleBottom = Double.infinity
    @State private var barBottom = 0.0
    @State private var listWidth = 0.0
    @ScaledMetric private var quantityWidth = 90.0

    /// Like Home's: rows stretched across a whole iPad are hard to read, and the photo would be enormous.
    private let maxContentWidth = 700.0

    /// At accessibility text sizes an amount column leaves the name too little room.
    private var stacksIngredients: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// Like Contacts: the big title is part of the page, and a small one
    /// fades into the bar once the big one has gone under it.
    private var isTitleInToolbar: Bool {
        titleBottom < barBottom
    }

    /// Looked up live, so edits show up straight away.
    private var recipe: Recipe? {
        recipeRepository.recipes.first { $0.id == recipeID } ?? deletedRecipe
    }

    var body: some View {
        Group {
            if let recipe {
                content(for: recipe)
            } else {
                ContentUnavailableView {
                    Label(displayTitle: "Recipe Not Found", systemImage: "fork.knife")
                } description: {
                    Text("It may have been deleted.")
                }
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

    private func setFavorite(_ isFavorite: Bool, for recipe: Recipe) {
        do throws(RecipeError) {
            try recipeRepository.setFavorite(isFavorite, for: recipe)
        } catch {
            favoriteError = error
        }
    }

    private func delete(_ recipe: Recipe) {
        do throws(RecipeError) {
            deletedRecipe = recipe
            try recipeRepository.delete(recipe, photoStore: photoStore)
            dismiss()
        } catch {
            deletedRecipe = nil
            deleteError = error
        }
    }

    private func sectionHeading(_ text: Text) -> some View {
        text
            .font(.display(.title3))
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        let layout = stacksIngredients
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        return layout {
            if !(stacksIngredients && ingredient.quantity.isEmpty) {
                Text(ingredient.quantity)
                    .fontWeight(.semibold)
                    .frame(width: stacksIngredients ? nil : quantityWidth, alignment: .leading)
            }
            Text(ingredient.name)
        }
        // One stop per ingredient: "200 g, Flour".
        .accessibilityElement(children: .combine)
    }

    private func stepRow(_ step: Step, number: Int) -> some View {
        // At accessibility text sizes the number goes above the step, which needs the whole width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
        return layout {
            Text("\(number).")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                if !step.text.isEmpty {
                    Text(step.text)
                }
                ForEach(step.bullets.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(step.bullets[index])
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func content(for recipe: Recipe) -> some View {
        List {
            if recipe.photoID != nil {
                Section {
                    RecipePhotoView(recipe: recipe, size: .full, placeholderFont: .largeTitle)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .listRowInsets(EdgeInsets())
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(recipe.title)
                    .font(.display(.largeTitle))
                    .accessibilityAddTraits(.isHeader)
                    .onGeometryChange(for: Double.self) { $0.frame(in: .scrollView).maxY } action: { titleBottom = $0 }

                if !recipe.mealTypes.isEmpty {
                    FlowLayout(spacing: 16) {
                        ForEach(recipe.mealTypes) { mealType in
                            // Not a Label: in a list it gets the row's icon column and loses its text.
                            HStack(spacing: 6) {
                                Image(systemName: mealType.systemImage)
                                    .foregroundStyle(.secondaryAccent)
                                Text(mealType.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .accessibilityElement(children: .combine)
                }
            }
            // Row settings go last, so the List still sees them.
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // One card per list, with each section's name as a heading row inside it.
            if !recipe.ingredientSections.isEmpty {
                Section("Ingredients") {
                    ForEach(recipe.ingredientSections.indices, id: \.self) { index in
                        let section = recipe.ingredientSections[index]
                        if let title = section.title {
                            sectionHeading(Text(title))
                        }
                        ForEach(section.items.indices, id: \.self) { itemIndex in
                            ingredientRow(section.items[itemIndex])
                        }
                    }
                }
                .listRowBackground(Color.surface)
            }

            if !recipe.stepSections.isEmpty {
                Section("Steps") {
                    // Named sections are numbered; steps start again at 1 in each.
                    let firstSectionNumber = recipe.stepSections.first?.title == nil ? 0 : 1
                    ForEach(recipe.stepSections.indices, id: \.self) { index in
                        let section = recipe.stepSections[index]
                        if let title = section.title {
                            sectionHeading(Text("\(index + firstSectionNumber). \(title)"))
                        }
                        ForEach(section.items.indices, id: \.self) { itemIndex in
                            stepRow(section.items[itemIndex], number: itemIndex + 1)
                        }
                    }
                }
                .listRowBackground(Color.surface)
            }

            if recipe.ingredients.isEmpty && recipe.steps.isEmpty {
                Text("This recipe doesn't have any ingredients or steps yet.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // At the bottom, like Calendar's Delete Event, so it's hard to hit by accident.
            Section {
                Button("Delete Recipe", role: .destructive) {
                    isConfirmingDelete = true
                }
                .frame(maxWidth: .infinity)
                .confirmationDialog(
                    "Delete \"\(recipe.title)\"?",
                    isPresented: $isConfirmingDelete,
                    titleVisibility: .visible
                ) {
                    Button("Delete Recipe", role: .destructive) {
                        delete(recipe)
                    }
                } message: {
                    Text("This can't be undone.")
                }
            }
            .listRowBackground(Color.surface)
        }
        .scrollContentBackground(.hidden)
        .contentMargins(
            .horizontal,
            listWidth > maxContentWidth ? (listWidth - maxContentWidth) / 2 : nil,
            for: .scrollContent
        )
        .onGeometryChange(for: Double.self) { $0.size.width } action: { listWidth = $0 }
        .sheet(isPresented: $isEditing) {
            RecipeEditorView(recipe: recipe)
        }
        .recipeErrorAlert("Couldn't Delete Recipe", error: $deleteError)
        .recipeErrorAlert("Couldn't Update Favorites", error: $favoriteError)
        // The bar is see-through, so content under it still counts as visible to the scroll view.
        .onScrollGeometryChange(for: Double.self) { $0.contentInsets.top } action: { _, inset in
            barBottom = inset
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    recipe.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: recipe.isFavorite ? "heart.fill" : "heart"
                ) {
                    setFavorite(!recipe.isFavorite, for: recipe)
                }
                .contentTransition(.symbolEffect(.replace))
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
            }
            ToolbarItem(placement: .principal) {
                Text(recipe.title)
                    .font(.display(.headline))
                    .lineLimit(1)
                    .opacity(isTitleInToolbar ? 1 : 0)
                    .animation(.easeOut(duration: 0.15), value: isTitleInToolbar)
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
    .environment(RecipePhotoStore())
    .environment(Connectivity())
}
