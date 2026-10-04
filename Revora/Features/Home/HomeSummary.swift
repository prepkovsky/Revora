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
    static let rowLimit = 6
    /// How long a recipe has to go unopened before Rediscover brings it back.
    static let rediscoverDays = 30

    /// The recipe opened most recently, at any time. `nil` until one has been opened.
    let continueRecipe: Recipe?
    /// Most recently opened first, so the row follows what people actually cook.
    let favorites: [Recipe]
    /// Not opened for `rediscoverDays` or more, or never opened and added that long ago.
    /// The one forgotten longest comes first.
    let rediscover: [Recipe]
    /// How many recipes are marked for each meal. Meals without any are left out.
    let mealCounts: [MealType: Int]
    let recipeCount: Int

    /// Most recently opened first.
    private let recipes: [Recipe]

    init(recipes: [Recipe], now: Date = .now) {
        let recent = recipes.sortedByRecent()
        self.recipes = recent
        continueRecipe = recent.first { $0.lastOpenedAt != nil }
        favorites = Array(recent.filter(\.isFavorite).prefix(Self.rowLimit))
        recipeCount = recipes.count

        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.rediscoverDays, to: now) ?? now
        let forgottenSince = { (recipe: Recipe) in recipe.lastOpenedAt ?? recipe.createdAt }
        rediscover = Array(
            recipes
                .filter { forgottenSince($0) < cutoff }
                .sorted { (forgottenSince($0), $0.id) < (forgottenSince($1), $1.id) }
                .prefix(Self.rowLimit)
        )

        var mealCounts: [MealType: Int] = [:]
        for mealType in recipes.flatMap(\.mealTypes) {
            mealCounts[mealType, default: 0] += 1
        }
        self.mealCounts = mealCounts
    }

    /// Surprise Me needs a choice, and the continue card already shows the last one.
    var canSurprise: Bool {
        recipeCount >= 2
    }

    /// For the row that answers "What's for dinner?", most recently opened first.
    func recipes(for mealType: MealType) -> [Recipe] {
        Array(recipes.filter { $0.mealTypes.contains(mealType) }.prefix(Self.rowLimit))
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
