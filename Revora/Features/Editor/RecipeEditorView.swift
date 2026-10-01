import SwiftUI

struct RecipeEditorView: View {
    private typealias IngredientRow = RecipeDraft.IngredientRow
    private typealias StepRow = RecipeDraft.StepRow

    private enum Field: Hashable {
        case title
        case quantity(IngredientRow.ID)
        case name(IngredientRow.ID)
        case step(StepRow.ID)
    }

    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(RecipePhotoStore.self) private var photoStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The recipe being edited, or `nil` for a new one.
    private let recipe: Recipe?
    private let originalDraft: RecipeDraft
    @State private var draft: RecipeDraft
    @State private var isPreparingPhoto = false
    @State private var saveErrorMessage: String?
    @State private var isConfirmingDiscard = false
    @FocusState private var focusedField: Field?
    @ScaledMetric private var quantityWidth = 90.0

    /// At accessibility text sizes an amount column leaves the name too little room.
    private var stacksIngredientFields: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var hasChanges: Bool {
        draft.hasChanges(from: originalDraft)
    }

    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        let draft = recipe.map(RecipeDraft.init(recipe:)) ?? RecipeDraft()
        originalDraft = draft
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                EditorPhotoSection(photo: $draft.photo, isPreparing: $isPreparingPhoto)

                Section("Title") {
                    TextField("Title", text: $draft.title, prompt: Text("e.g. Banana Bread"))
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit(focusFirstIngredient)
                }
                .listRowBackground(Color.surface)

                Section("Ingredients") {
                    ForEach($draft.ingredients) { $row in
                        let layout = stacksIngredientFields ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
                        layout {
                            TextField("Amount", text: $row.quantity, prompt: Text("Amount"))
                                .autocorrectionDisabled()
                                .frame(width: stacksIngredientFields ? nil : quantityWidth)
                                .focused($focusedField, equals: .quantity(row.id))
                                .submitLabel(.next)
                                .onSubmit { focusedField = .name(row.id) }
                            Divider()
                            TextField("Ingredient", text: $row.name, prompt: Text("Ingredient"))
                                .focused($focusedField, equals: .name(row.id))
                                .submitLabel(.next)
                                .onSubmit { focusIngredient(after: row) }
                        }
                    }
                    .onDelete { draft.ingredients.remove(atOffsets: $0) }
                    .onMove { draft.ingredients.move(fromOffsets: $0, toOffset: $1) }

                    Button("Add Ingredient", systemImage: "plus.circle.fill", action: addIngredient)
                }
                .listRowBackground(Color.surface)

                Section("Steps") {
                    ForEach($draft.steps) { $step in
                        let number = stepNumber(of: step)
                        // Not .firstTextBaseline: an empty vertical text field reports its baseline a line too low.
                        HStack(alignment: .top) {
                            Text("\(number).")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            TextField("Step \(number)", text: $step.text, prompt: Text("Describe this step"), axis: .vertical)
                                .focused($focusedField, equals: .step(step.id))
                                .submitLabel(.next)
                                .onSubmit { focusStep(after: step) }
                                // Some iOS versions type Return in a vertical text field as a line break
                                // instead of submitting, and pasted text can contain them too.
                                .onChange(of: step.text) {
                                    if step.removeLineBreaks() {
                                        focusStep(after: step)
                                    }
                                }
                        }
                    }
                    .onDelete { draft.steps.remove(atOffsets: $0) }
                    .onMove { draft.steps.move(fromOffsets: $0, toOffset: $1) }

                    Button("Add Step", systemImage: "plus.circle.fill", action: addStep)
                }
                .listRowBackground(Color.surface)
            }
            // Always editing, like Contacts: rows show their delete and reorder controls.
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(.appBackground)
            .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                        .confirmationDialog(
                            recipe == nil ? "Discard this recipe?" : "Discard your changes?",
                            isPresented: $isConfirmingDiscard,
                            titleVisibility: .visible
                        ) {
                            Button("Discard Changes", role: .destructive) {
                                dismiss()
                            }
                            Button("Keep Editing", role: .cancel) {}
                        }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.canSave || isPreparingPhoto)
                }
            }
            .alert(
                "Couldn't Save Recipe",
                isPresented: Binding { saveErrorMessage != nil } set: { if !$0 { saveErrorMessage = nil } },
                presenting: saveErrorMessage
            ) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
            .onAppear {
                if recipe == nil {
                    focusedField = .title
                }
            }
        }
        // Swiping down would skip the discard confirmation.
        .interactiveDismissDisabled(hasChanges)
    }

    private func stepNumber(of step: StepRow) -> Int {
        (draft.steps.firstIndex { $0.id == step.id } ?? 0) + 1
    }

    private func addIngredient() {
        let row = IngredientRow()
        draft.ingredients.append(row)
        focusedField = .quantity(row.id)
    }

    private func addStep() {
        let step = StepRow()
        draft.steps.append(step)
        focusedField = .step(step.id)
    }

    private func focusFirstIngredient() {
        if let first = draft.ingredients.first {
            focusedField = .quantity(first.id)
        } else {
            addIngredient()
        }
    }

    private func focusFirstStep() {
        if let first = draft.steps.first {
            focusedField = .step(first.id)
        } else {
            addStep()
        }
    }

    /// Return on the last row starts a new one. On an empty last row it removes
    /// that row and moves on to the steps.
    private func focusIngredient(after row: IngredientRow) {
        guard let index = draft.ingredients.firstIndex(where: { $0.id == row.id }) else { return }
        let next = draft.ingredients.index(after: index)
        if next < draft.ingredients.endIndex {
            focusedField = .quantity(draft.ingredients[next].id)
        } else if !row.isBlank {
            addIngredient()
        } else {
            draft.ingredients.remove(at: index)
            focusFirstStep()
        }
    }

    /// Return on the last step starts a new one. On an empty last step it removes
    /// that step and closes the keyboard.
    private func focusStep(after step: StepRow) {
        guard let index = draft.steps.firstIndex(where: { $0.id == step.id }) else { return }
        let next = draft.steps.index(after: index)
        if next < draft.steps.endIndex {
            focusedField = .step(draft.steps[next].id)
        } else if !step.isBlank {
            addStep()
        } else {
            draft.steps.remove(at: index)
            focusedField = nil
        }
    }

    private func cancel() {
        if hasChanges {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard draft.canSave, !isPreparingPhoto else { return }
        do {
            if let recipe {
                try saveChanges(to: recipe)
            } else {
                try createRecipe()
            }
            dismiss()
        } catch let error as RecipeError {
            saveErrorMessage = error.message
        } catch let error as PhotoError {
            saveErrorMessage = error.message
        } catch {
            saveErrorMessage = RecipeError.unknown.message
        }
    }

    private func createRecipe() throws {
        let recipeID = try recipeRepository.newRecipeID()
        _ = try recipeRepository.create(
            id: recipeID,
            title: draft.trimmedTitle,
            ingredients: draft.trimmedIngredients,
            steps: draft.trimmedSteps,
            photoID: savePhoto(recipeID: recipeID)
        )
    }

    private func saveChanges(to recipe: Recipe) throws {
        // The latest version, so a change made meanwhile, like a favorite, isn't undone.
        let latest = recipeRepository.recipes.first { $0.id == recipe.id } ?? recipe
        let photoID = try savePhoto(recipeID: recipe.id)
        try recipeRepository.update(draft.applied(to: latest, photoID: photoID))
        // Only once the recipe no longer points at the old photo. Firestore keeps writes in order.
        if let oldPhotoID = latest.photoID, oldPhotoID != photoID {
            try? photoStore.delete(photoID: oldPhotoID, recipeID: recipe.id)
        }
    }

    /// A newly picked photo is saved before the recipe, so the recipe never points at a photo that isn't there.
    private func savePhoto(recipeID: Recipe.ID) throws -> String? {
        switch draft.photo {
        case .picked(let picked):
            return try photoStore.save(picked.prepared, recipeID: recipeID)
        case .saved(let photoID, _):
            return photoID
        case nil:
            return nil
        }
    }
}

#Preview {
    RecipeEditorView()
        .environment(RecipeRepository())
        .environment(RecipePhotoStore())
}
