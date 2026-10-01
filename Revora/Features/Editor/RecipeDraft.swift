import Foundation

/// What the editor holds while people type, before it's saved as a `Recipe`.
struct RecipeDraft: Equatable {
    var title = ""

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty
    }
}
