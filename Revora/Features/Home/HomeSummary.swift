import Foundation

/// What Home shows, worked out from the user's recipes.
struct HomeSummary {
    /// Enough to fill a row on a phone; "See All" has the rest.
    static let favoritesLimit = 6

    /// The recipe opened most recently, at any time. `nil` until one has been opened.
    let continueRecipe: Recipe?
    /// Most recently opened first, so the row follows what people actually cook.
    let favorites: [Recipe]
    let recipeCount: Int

    private let recipes: [Recipe]

    init(recipes: [Recipe]) {
        let recent = recipes.sortedByRecent()
        self.recipes = recipes
        continueRecipe = recent.first { $0.lastOpenedAt != nil }
        favorites = Array(recent.filter(\.isFavorite).prefix(Self.favoritesLimit))
        recipeCount = recipes.count
    }

    /// Surprise Me needs a choice, and the continue card already shows the last one.
    var canSurprise: Bool {
        recipeCount >= 2
    }

    /// A random recipe other than the one in the continue card.
    func surpriseRecipe(using generator: inout some RandomNumberGenerator) -> Recipe? {
        recipes.filter { $0.id != continueRecipe?.id }.randomElement(using: &generator)
    }
}
