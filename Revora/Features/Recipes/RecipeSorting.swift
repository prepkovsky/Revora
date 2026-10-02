import Foundation

extension Sequence<Recipe> {
    /// A→Z the way Finder sorts names: ignoring case, with "Soup 2" before "Soup 10".
    /// Recipes with the same title keep a stable order, oldest first.
    func sortedByTitle() -> [Recipe] {
        sorted { first, second in
            switch first.title.localizedStandardCompare(second.title) {
            case .orderedAscending: true
            case .orderedDescending: false
            case .orderedSame: (first.createdAt, first.id) < (second.createdAt, second.id)
            }
        }
    }

    /// Most recently used first. Ties go to the newer recipe, so the order never jumps around.
    func sortedByRecent() -> [Recipe] {
        sorted { first, second in
            (first.lastUsedAt, first.createdAt, first.id) > (second.lastUsedAt, second.createdAt, second.id)
        }
    }
}

extension Recipe {
    /// When the recipe was last opened, created or edited. Creating counts so a new recipe
    /// shows up in Recent before anyone opens it; editing already happens from the open recipe.
    var lastUsedAt: Date {
        max(updatedAt, lastOpenedAt ?? updatedAt)
    }
}
