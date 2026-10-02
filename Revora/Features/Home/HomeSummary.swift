import Foundation

/// What Home shows, worked out from the user's recipes.
struct HomeSummary {
    /// What Surprise Me picks from.
    struct SurprisePool {
        let recipes: [Recipe]
        /// The meal they're all for, or `nil` when no recipe fits and it falls back to any.
        let mealType: MealType?
    }

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

    /// Recipes for this meal if there are any, otherwise all of them, so Surprise Me always
    /// has something.
    func surprisePool(for mealType: MealType) -> SurprisePool {
        let forMeal = recipes.filter { $0.mealTypes.contains(mealType) }
        return forMeal.isEmpty
            ? SurprisePool(recipes: avoidingContinueRecipe(recipes), mealType: nil)
            : SurprisePool(recipes: avoidingContinueRecipe(forMeal), mealType: mealType)
    }

    /// Leaves out the continue card's recipe, which is already on screen, but only when there's
    /// another choice. Otherwise the only dinner would lose to an untagged recipe once it's opened.
    private func avoidingContinueRecipe(_ candidates: [Recipe]) -> [Recipe] {
        let others = candidates.filter { $0.id != continueRecipe?.id }
        return others.isEmpty ? candidates : others
    }
}
