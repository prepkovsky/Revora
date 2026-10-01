import SwiftUI

struct RecipeEditorView: View {
    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(\.dismiss) private var dismiss

    @State private var draft = RecipeDraft()
    @State private var saveError: RecipeError?
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $draft.title, prompt: Text("e.g. Banana Bread"))
                        .focused($isTitleFocused)
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
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
                isTitleFocused = true
            }
        }
    }

    private func save() {
        guard draft.canSave else { return }
        do throws(RecipeError) {
            _ = try recipeRepository.create(title: draft.trimmedTitle, ingredients: [], steps: [])
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
