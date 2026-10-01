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

    struct StepRow: Identifiable, Equatable {
        let id = UUID()
        var text = ""

        var isBlank: Bool {
            trimmed(text).isEmpty
        }

        /// Each step is one paragraph, so Return moves on to the next step instead of
        /// starting a new line. Returns whether there was a line break to remove.
        mutating func removeLineBreaks() -> Bool {
            guard text.contains(where: \.isNewline) else { return false }
            text = text.split(whereSeparator: \.isNewline).joined(separator: " ")
            return true
        }
    }

    var title = ""
    var ingredients: [IngredientRow] = []
    var steps: [StepRow] = []

    var trimmedTitle: String {
        trimmed(title)
    }

    /// Blank rows are dropped. A row with only a quantity is kept, so nothing people typed is lost.
    var trimmedIngredients: [Ingredient] {
        ingredients
            .filter { !$0.isBlank }
            .map { Ingredient(name: trimmed($0.name), quantity: trimmed($0.quantity)) }
    }

    var trimmedSteps: [String] {
        steps.filter { !$0.isBlank }.map { trimmed($0.text) }
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty
    }

    /// Compares what would be saved, so blank rows and stray spaces don't count as changes.
    func hasChanges(from original: RecipeDraft) -> Bool {
        trimmedTitle != original.trimmedTitle
            || trimmedIngredients != original.trimmedIngredients
            || trimmedSteps != original.trimmedSteps
    }
}

private func trimmed(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}
