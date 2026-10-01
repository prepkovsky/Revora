import SwiftUI

struct RecipeEditorView: View {
    private typealias IngredientRow = RecipeDraft.IngredientRow

    private enum Field: Hashable {
        case title
        case quantity(IngredientRow.ID)
        case name(IngredientRow.ID)
    }

    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(\.dismiss) private var dismiss

    @State private var draft = RecipeDraft()
    @State private var saveError: RecipeError?
    @FocusState private var focusedField: Field?
    @ScaledMetric private var quantityWidth = 90.0

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
                    Button("Cancel") {
                        dismiss()
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
    }

    private func addIngredient() {
        let row = IngredientRow()
        draft.ingredients.append(row)
        focusedField = .quantity(row.id)
    }

    private func focusFirstIngredient() {
        if let first = draft.ingredients.first {
            focusedField = .quantity(first.id)
        } else {
            addIngredient()
        }
    }

    /// Return on the last row starts a new one, unless that row is still empty.
    private func focusIngredient(after row: IngredientRow) {
        guard let index = draft.ingredients.firstIndex(where: { $0.id == row.id }) else { return }
        let next = draft.ingredients.index(after: index)
        if next < draft.ingredients.endIndex {
            focusedField = .quantity(draft.ingredients[next].id)
        } else if !row.isBlank {
            addIngredient()
        } else {
            focusedField = nil
        }
    }

    private func save() {
        guard draft.canSave else { return }
        do throws(RecipeError) {
            _ = try recipeRepository.create(
                title: draft.trimmedTitle,
                ingredients: draft.trimmedIngredients,
                steps: []
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
