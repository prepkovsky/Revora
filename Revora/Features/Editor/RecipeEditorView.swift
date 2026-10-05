import SwiftUI

struct RecipeEditorView: View {
    private typealias IngredientRow = RecipeDraft.IngredientRow
    private typealias StepRow = RecipeDraft.StepRow
    private typealias BulletRow = RecipeDraft.BulletRow

    private enum Field: Hashable {
        case title
        /// A section's name, in either list.
        case section(UUID)
        case quantity(IngredientRow.ID)
        case name(IngredientRow.ID)
        case step(StepRow.ID)
        case bullet(BulletRow.ID, step: StepRow.ID)
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
    /// Steps under a numbered section sit in a little, so their numbers don't read as sections.
    @ScaledMetric private var sectionIndent = 22.0

    /// At accessibility text sizes an amount column leaves the name too little room.
    private var stacksIngredientFields: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var hasChanges: Bool {
        draft.hasChanges(from: originalDraft)
    }

    /// The step being typed in, directly or in one of its bullet points.
    private var focusedStepID: StepRow.ID? {
        switch focusedField {
        case .step(let id), .bullet(_, let id): id
        default: nil
        }
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
                        // With a prompt, the field's own title doesn't reach VoiceOver.
                        .accessibilityLabel("Title")
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit(focusFirstIngredient)
                }
                .listRowBackground(Color.surface)

                Section {
                    FlowLayout {
                        ForEach(MealType.allCases) { mealType in
                            MealTypeChip(
                                mealType: mealType,
                                isSelected: draft.mealTypes.contains(mealType),
                                background: .appBackground
                            ) {
                                withAnimation(.snappy) {
                                    draft.mealTypes.formSymmetricDifference([mealType])
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Meal")
                } footer: {
                    Text("Pick any that fit. Surprise Me on Home suggests recipes for the time of day.")
                }
                .listRowBackground(Color.surface)

                Section("Ingredients") {
                    ForEach($draft.ingredients) { $row in
                        Group {
                            if row.isSection {
                                sectionField($row.name, id: row.id) { focusIngredient(afterSection: row) }
                            } else {
                                ingredientFields($row)
                            }
                        }
                        .accessibilityActions {
                            rowActions(\.ingredients, id: row.id, delete: row.isSection ? "Delete Section" : "Delete Ingredient")
                        }
                    }
                    .onDelete { draft.ingredients.remove(atOffsets: $0) }
                    .onMove { draft.ingredients.move(fromOffsets: $0, toOffset: $1) }

                    Button("Add Ingredient", systemImage: "plus.circle.fill") { addIngredient() }
                    Button("Add Section", systemImage: "text.badge.plus", action: addIngredientSection)
                }
                .listRowBackground(Color.surface)

                Section("Steps") {
                    let numbers = draft.stepNumbers
                    let sectionedSteps = Set(draft.steps.drop { !$0.isSection }.map(\.id))
                    ForEach($draft.steps) { $row in
                        let number = numbers[row.id] ?? 0
                        Group {
                            if row.isSection {
                                sectionField($row.text, id: row.id, number: number) { focusStep(afterSection: row) }
                            } else {
                                stepFields($row, number: number)
                                    .padding(.leading, sectionedSteps.contains(row.id) ? sectionIndent : 0)
                            }
                        }
                        .accessibilityActions {
                            rowActions(\.steps, id: row.id, delete: row.isSection ? "Delete Section" : "Delete Step")
                        }
                    }
                    .onDelete { draft.steps.remove(atOffsets: $0) }
                    .onMove { draft.steps.move(fromOffsets: $0, toOffset: $1) }

                    Button("Add Step", systemImage: "plus.circle.fill") { addStep() }
                    Button("Add Section", systemImage: "text.badge.plus", action: addStepSection)
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
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedStepID != nil {
                        Button("Add Bullet Point", systemImage: "list.bullet", action: addBulletAtFocus)
                        Spacer()
                    }
                }
            }
            .onChange(of: focusedField) { previousField, _ in
                removeIfBlankBullet(previousField)
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
        // On iPad a form sheet would show little more than the photo.
        .presentationSizing(.page)
    }

    /// A section's name in either list. Step sections show their number.
    private func sectionField(_ name: Binding<String>, id: UUID, number: Int? = nil, onSubmit: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline) {
            if let number {
                Text("\(number).")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            // Wraps, like the steps, so long names aren't cut off at large text sizes.
            TextField(text: name, prompt: Text("Section name"), axis: .vertical) {
                if let number {
                    Text("Section \(number)")
                } else {
                    Text("Section")
                }
            }
            .accessibilityLabel(number.map { "Section \($0)" } ?? "Section")
            .focused($focusedField, equals: .section(id))
            .submitLabel(.next)
            .onSubmit(onSubmit)
            // Return can arrive as a line break, as in a step.
            .onChange(of: name.wrappedValue) {
                if name.wrappedValue.removeLineBreaks() {
                    onSubmit()
                }
            }
        }
        .font(.headline)
    }

    private func ingredientFields(_ row: Binding<IngredientRow>) -> some View {
        let id = row.wrappedValue.id
        let name = row.wrappedValue.name.trimmingCharacters(in: .whitespaces)
        let layout = stacksIngredientFields ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())
        return layout {
            TextField("Amount", text: row.quantity, prompt: Text("Amount"))
                // The row's reorder handle takes this label too, so it says which ingredient it moves.
                .accessibilityLabel(name.isEmpty ? "Amount" : "Amount of \(name)")
                .autocorrectionDisabled()
                .frame(width: stacksIngredientFields ? nil : quantityWidth)
                .focused($focusedField, equals: .quantity(id))
                .submitLabel(.next)
                .onSubmit { focusedField = .name(id) }
            Divider()
            TextField("Ingredient", text: row.name, prompt: Text("Ingredient"), axis: .vertical)
                .accessibilityLabel("Ingredient")
                .focused($focusedField, equals: .name(id))
                .submitLabel(.next)
                .onSubmit { focusIngredient(after: row.wrappedValue) }
                .onChange(of: row.wrappedValue.name) {
                    if row.wrappedValue.removeLineBreaks() {
                        focusIngredient(after: row.wrappedValue)
                    }
                }
        }
    }

    /// The step's text with its bullet points underneath, all in one row, so they move and delete together.
    private func stepFields(_ step: Binding<StepRow>, number: Int) -> some View {
        let id = step.wrappedValue.id
        // Not .firstTextBaseline: an empty vertical text field reports its baseline a line too low.
        return HStack(alignment: .top) {
            Text("\(number).")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                TextField("Step \(number)", text: step.text, prompt: Text("Describe this step"), axis: .vertical)
                    .accessibilityLabel("Step \(number)")
                    .focused($focusedField, equals: .step(id))
                    .submitLabel(.next)
                    .onSubmit { focusStep(afterText: step.wrappedValue) }
                    // Some iOS versions type Return in a vertical text field as a line break
                    // instead of submitting, and pasted text can contain them too.
                    .onChange(of: step.wrappedValue.text) {
                        if step.wrappedValue.removeLineBreaks() {
                            focusStep(afterText: step.wrappedValue)
                        }
                    }

                ForEach(step.bullets) { $bullet in
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        TextField("Bullet point", text: $bullet.text, prompt: Text("Bullet point"), axis: .vertical)
                            .accessibilityLabel("Bullet point")
                            .focused($focusedField, equals: .bullet(bullet.id, step: id))
                            .submitLabel(.next)
                            .onSubmit { focusBullet(after: bullet, inStep: id) }
                            .onChange(of: bullet.text) {
                                if bullet.removeLineBreaks() {
                                    focusBullet(after: bullet, inStep: id)
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: VoiceOver

    /// VoiceOver can't reach a row's delete button, and dragging its handle is awkward,
    /// so the row's fields offer the same as actions.
    @ViewBuilder
    private func rowActions<Row: Identifiable>(
        _ rows: WritableKeyPath<RecipeDraft, [Row]>,
        id: Row.ID,
        delete title: LocalizedStringResource
    ) -> some View {
        let index = draft[keyPath: rows].firstIndex { $0.id == id }
        // VoiceOver offers these last to first: Move Up, Move Down, then Delete.
        Button(title) {
            focusedField = nil
            removeAfterFocusMoves { $0[keyPath: rows].removeAll { $0.id == id } }
        }
        if let index, index < draft[keyPath: rows].count - 1 {
            Button("Move Down") { moveRow(rows, id: id, by: 1) }
        }
        if let index, index > 0 {
            Button("Move Up") { moveRow(rows, id: id, by: -1) }
        }
    }

    /// One place at a time, past section names too, like dragging the row.
    private func moveRow<Row: Identifiable>(_ rows: WritableKeyPath<RecipeDraft, [Row]>, id: Row.ID, by offset: Int) {
        guard let index = draft[keyPath: rows].firstIndex(where: { $0.id == id }),
              draft[keyPath: rows].indices.contains(index + offset) else { return }
        draft[keyPath: rows].swapAt(index, index + offset)
    }

    // MARK: Ingredients

    private func addIngredient(at index: Int? = nil) {
        let row = IngredientRow()
        draft.ingredients.insert(row, at: index ?? draft.ingredients.endIndex)
        focusedField = .quantity(row.id)
    }

    /// At the end: a list followed by a section like "For the garnish" is common.
    private func addIngredientSection() {
        let row = IngredientRow(isSection: true)
        draft.ingredients.append(row)
        focusedField = .section(row.id)
    }

    private func focus(_ row: IngredientRow) {
        focusedField = row.isSection ? .section(row.id) : .quantity(row.id)
    }

    private func focusFirstIngredient() {
        if let first = draft.ingredients.first {
            focus(first)
        } else {
            addIngredient()
        }
    }

    /// Return on a section's name moves to its first ingredient, adding one if it has none.
    /// On an empty name it removes the section and moves on.
    private func focusIngredient(afterSection row: IngredientRow) {
        guard let index = draft.ingredients.firstIndex(where: { $0.id == row.id }) else { return }
        let next = draft.ingredients.dropFirst(index + 1).first
        if row.isBlank {
            removeIngredient(row, movingTo: next)
        } else if let next, !next.isSection {
            focusedField = .quantity(next.id)
        } else {
            addIngredient(at: index + 1)
        }
    }

    /// Return on the last ingredient of a section, or of the list, starts a new one below it.
    /// On an empty one it removes that row and moves on to the next section, or to the steps.
    private func focusIngredient(after row: IngredientRow) {
        guard let index = draft.ingredients.firstIndex(where: { $0.id == row.id }) else { return }
        let next = draft.ingredients.dropFirst(index + 1).first
        if let next, !next.isSection {
            focusedField = .quantity(next.id)
        } else if !row.isBlank {
            addIngredient(at: index + 1)
        } else {
            removeIngredient(row, movingTo: next)
        }
    }

    private func removeIngredient(_ row: IngredientRow, movingTo next: IngredientRow?) {
        if let next {
            focus(next)
        } else {
            focusFirstStep()
        }
        removeAfterFocusMoves { $0.ingredients.removeAll { $0.id == row.id } }
    }

    // MARK: Steps

    private func addStep(at index: Int? = nil) {
        let step = StepRow()
        draft.steps.insert(step, at: index ?? draft.steps.endIndex)
        focusedField = .step(step.id)
    }

    /// Numbered sections need every step to be in one, so the first section goes above the
    /// steps already there and they become its steps. Later sections go at the end.
    private func addStepSection() {
        let row = StepRow(isSection: true)
        if draft.steps.contains(where: \.isSection) {
            draft.steps.append(row)
        } else {
            draft.steps.insert(row, at: 0)
        }
        focusedField = .section(row.id)
    }

    private func focus(_ row: StepRow?) {
        focusedField = row.map { $0.isSection ? .section($0.id) : .step($0.id) }
    }

    private func focusFirstStep() {
        if let first = draft.steps.first {
            focus(first)
        } else {
            addStep()
        }
    }

    /// Return on a section's name moves to its first step, adding one if it has none.
    /// On an empty name it removes the section and moves on.
    private func focusStep(afterSection row: StepRow) {
        guard let index = draft.steps.firstIndex(where: { $0.id == row.id }) else { return }
        let next = draft.steps.dropFirst(index + 1).first
        if row.isBlank {
            removeStep(row, movingTo: next)
        } else if let next, !next.isSection {
            focusedField = .step(next.id)
        } else {
            addStep(at: index + 1)
        }
    }

    /// Return in a step's text moves to its first bullet point, if it has any.
    private func focusStep(afterText step: StepRow) {
        if let bullet = step.bullets.first {
            focusedField = .bullet(bullet.id, step: step.id)
        } else {
            focusStep(after: step)
        }
    }

    /// Return at the end of the last step of a section, or of the list, starts a new one below it.
    /// On an empty one it removes that step and moves on to the next section, or closes the keyboard.
    private func focusStep(after step: StepRow) {
        guard let index = draft.steps.firstIndex(where: { $0.id == step.id }) else { return }
        let next = draft.steps.dropFirst(index + 1).first
        if let next, !next.isSection {
            focusedField = .step(next.id)
        } else if !step.isBlank {
            addStep(at: index + 1)
        } else {
            removeStep(step, movingTo: next)
        }
    }

    private func removeStep(_ row: StepRow, movingTo next: StepRow?) {
        focus(next)
        removeAfterFocusMoves { $0.steps.removeAll { $0.id == row.id } }
    }

    // MARK: Bullet points

    private func addBullet(toStep stepID: StepRow.ID, at position: Int? = nil) {
        guard let index = draft.steps.firstIndex(where: { $0.id == stepID }) else { return }
        let bullet = BulletRow()
        draft.steps[index].bullets.insert(bullet, at: position ?? draft.steps[index].bullets.endIndex)
        focusedField = .bullet(bullet.id, step: stepID)
    }

    /// Right under where people are typing: below the step's text, or after the bullet point.
    private func addBulletAtFocus() {
        switch focusedField {
        case .step(let stepID):
            addBullet(toStep: stepID, at: 0)
        case .bullet(let bulletID, let stepID):
            let index = draft.steps.first { $0.id == stepID }?.bullets.firstIndex { $0.id == bulletID }
            addBullet(toStep: stepID, at: index.map { $0 + 1 })
        default:
            break
        }
    }

    /// Bullet points have no delete button of their own, so an empty one goes once people move on.
    private func removeIfBlankBullet(_ field: Field?) {
        guard case .bullet(let bulletID, let stepID) = field,
              let step = draft.steps.first(where: { $0.id == stepID }),
              step.bullets.first(where: { $0.id == bulletID })?.isBlank == true else { return }
        removeAfterFocusMoves { draft in
            guard let stepIndex = draft.steps.firstIndex(where: { $0.id == stepID }) else { return }
            draft.steps[stepIndex].bullets.removeAll { $0.id == bulletID && $0.isBlank }
        }
    }

    /// Return in a bullet point starts the next one. On an empty last one it removes it and
    /// moves on to the next step, like ending a list in Notes.
    private func focusBullet(after bullet: BulletRow, inStep stepID: StepRow.ID) {
        guard let step = draft.steps.first(where: { $0.id == stepID }),
              let index = step.bullets.firstIndex(where: { $0.id == bullet.id }) else { return }
        if index + 1 < step.bullets.endIndex {
            focusedField = .bullet(step.bullets[index + 1].id, step: stepID)
        } else if !bullet.isBlank {
            addBullet(toStep: stepID, at: index + 1)
        } else {
            var rest = step
            rest.bullets.remove(at: index)
            focusStep(after: rest)
            removeAfterFocusMoves { draft in
                guard let stepIndex = draft.steps.firstIndex(where: { $0.id == stepID }) else { return }
                draft.steps[stepIndex].bullets.removeAll { $0.id == bullet.id }
            }
        }
    }

    /// A field that's losing focus writes its text back to its row, and a step's
    /// multi-line field crashed when that row was already gone. So the row goes
    /// once focus has moved on.
    private func removeAfterFocusMoves(_ removal: @escaping (inout RecipeDraft) -> Void) {
        Task {
            removal(&draft)
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
            ingredientSections: draft.trimmedIngredientSections,
            stepSections: draft.trimmedStepSections,
            mealTypes: draft.mealTypes.inDisplayOrder(),
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
        .environment(Connectivity())
}
