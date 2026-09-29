import SwiftUI

struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView("New Recipe", systemImage: "square.and.pencil")
                .background(.appBackground)
                .navigationTitle("New Recipe")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    RecipeEditorView()
}
