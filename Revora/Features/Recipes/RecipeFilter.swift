import Foundation

/// The segments at the top of the Recipes tab.
enum RecipeFilter: CaseIterable, Identifiable {
    case recent
    case all
    case favorites

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .recent: "Recent"
        case .all: "All"
        case .favorites: "Favorites"
        }
    }

    /// How long a recipe stays in Recent after it was last opened, created or edited.
    static let recentDays = 3

    /// The recipes this segment shows, narrowed to titles that contain the search text.
    /// Matching ignores case and accents, so "creme" finds "Crème Brûlée".
    func apply(to recipes: [Recipe], searchText: String, now: Date = .now) -> [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = query.isEmpty ? recipes : recipes.filter { $0.title.localizedStandardContains(query) }
        return switch self {
        case .recent: matches.filter { $0.lastUsedAt >= Self.recentCutoff(now: now) }.sortedByRecent()
        case .all: matches.sortedByTitle()
        case .favorites: matches.filter(\.isFavorite).sortedByTitle()
        }
    }

    private static func recentCutoff(now: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -recentDays, to: now) ?? now
    }
}
