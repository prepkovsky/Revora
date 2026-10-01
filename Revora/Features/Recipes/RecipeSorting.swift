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
}
