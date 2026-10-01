import Foundation

/// What the editor holds while people type, before it's saved as a `Recipe`.
struct RecipeDraft: Equatable {
    /// An ingredient being edited. The ID keeps rows apart while they're added, moved and deleted.
    struct IngredientRow: Identifiable, Equatable {
        let id = UUID()
        var quantity = ""
        var name = ""

        var isBlank: Bool {
            trimmed(quantity).isEmpty && trimmed(name).isEmpty
        }
    }

    var title = ""
    var ingredients: [IngredientRow] = []

    var trimmedTitle: String {
        trimmed(title)
    }

    /// Blank rows are dropped. A row with only a quantity is kept, so nothing people typed is lost.
    var trimmedIngredients: [Ingredient] {
        ingredients
            .filter { !$0.isBlank }
            .map { Ingredient(name: trimmed($0.name), quantity: trimmed($0.quantity)) }
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty
    }
}

private func trimmed(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}
