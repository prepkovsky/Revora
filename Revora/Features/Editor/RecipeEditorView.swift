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
    @Environment(\.dismiss) private var dismiss

    private let originalDraft = RecipeDraft()
    @State private var draft = RecipeDraft()
    @State private var saveError: RecipeError?
    @State private var isConfirmingDiscard = false
    @FocusState private var focusedField: Field?
    @ScaledMetric private var quantityWidth = 90.0

    private var hasChanges: Bool {
        draft.hasChanges(from: originalDraft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $draft.title, prompt: Text("e.g. Banana Bread"))
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit(focusFirstIngredient)
                }
                .listRowBackground(Color.surface)

                Section("Ingredients") {
                    ForEach($draft.ingredients) { $row in
                        HStack {
                            TextField("Amount", text: $row.quantity, prompt: Text("Amount"))
                                .autocorrectionDisabled()
                                .frame(width: quantityWidth)
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
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                        .confirmationDialog("Discard this recipe?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                            Button("Discard Changes", role: .destructive) {
                                dismiss()
                            }
                            Button("Keep Editing", role: .cancel) {}
                        }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.canSave)
                }
            }
            .alert(
                "Couldn't Save Recipe",
                isPresented: Binding { saveError != nil } set: { if !$0 { saveError = nil } },
                presenting: saveError
            ) { _ in
                Button("OK") {}
            } message: { error in
                Text(error.message)
            }
            .onAppear {
                focusedField = .title
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
        guard draft.canSave else { return }
        do throws(RecipeError) {
            _ = try recipeRepository.create(
                title: draft.trimmedTitle,
                ingredients: draft.trimmedIngredients,
                steps: draft.trimmedSteps
            )
            dismiss()
        } catch {
            saveError = error
        }
    }
}

#Preview {
    RecipeEditorView()
        .environment(RecipeRepository())
}
