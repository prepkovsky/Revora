import Foundation
import Testing
@testable import Revora

struct HomeSummaryTests {
    private static let day: TimeInterval = 24 * 60 * 60
    private let now = Date(timeIntervalSince1970: 100 * day)

    private func recipe(
        _ title: String,
        mealTypes: [MealType] = [],
        isFavorite: Bool = false,
        openedDaysAgo: Double? = nil,
        createdDaysAgo: Double = 60
    ) -> Recipe {
        Recipe(
            id: title,
            title: title,
            mealTypes: mealTypes,
            isFavorite: isFavorite,
            createdAt: now.addingTimeInterval(-createdDaysAgo * Self.day),
            updatedAt: now,
            lastOpenedAt: openedDaysAgo.map { now.addingTimeInterval(-$0 * Self.day) }
        )
    }

    private func homeSummary(_ recipes: [Recipe]) -> HomeSummary {
        HomeSummary(recipes: recipes, now: now)
    }

    @Test func continueShowsTheLastOpenedRecipeHoweverLongAgo() {
        let summary = homeSummary([recipe("Soup", openedDaysAgo: 40), recipe("Pie", openedDaysAgo: 90), recipe("New")])
        #expect(summary.continueRecipe?.title == "Soup")
    }

    @Test func continueIsHiddenUntilARecipeIsOpened() {
        #expect(homeSummary([recipe("New"), recipe("Newer")]).continueRecipe == nil)
    }

    @Test func favoritesAreMostRecentlyOpenedFirst() {
        let summary = homeSummary([
            recipe("Never opened", isFavorite: true),
            recipe("Yesterday", isFavorite: true, openedDaysAgo: 1),
            recipe("Not a favorite", openedDaysAgo: 0),
            recipe("Last week", isFavorite: true, openedDaysAgo: 7),
        ])
        #expect(summary.favorites.map(\.title) == ["Yesterday", "Last week", "Never opened"])
    }

    @Test func favoritesStopAtTheLimit() {
        let recipes = (0..<10).map { recipe("Favorite \($0)", isFavorite: true, openedDaysAgo: Double($0)) }
        let summary = homeSummary(recipes)
        #expect(summary.favorites.count == HomeSummary.rowLimit)
        #expect(summary.favorites.first?.title == "Favorite 0")
    }

    @Test func surpriseSkipsTheContinueRecipe() {
        let summary = homeSummary([recipe("Last opened", openedDaysAgo: 0), recipe("Other")])
        #expect(summary.canSurprise)
        #expect(summary.surprisePool(for: .dinner).recipes.map(\.title) == ["Other"])
    }

    @Test func surprisePrefersRecipesForTheMeal() {
        let summary = homeSummary([
            recipe("Pancakes", mealTypes: [.breakfast, .dessert]),
            recipe("Soup", mealTypes: [.lunch, .dinner]),
            recipe("Toast", mealTypes: [.breakfast]),
        ])
        let pool = summary.surprisePool(for: .breakfast)
        #expect(pool.mealType == .breakfast)
        #expect(Set(pool.recipes.map(\.title)) == ["Pancakes", "Toast"])
    }

    @Test func surpriseFallsBackToAnyRecipeWhenNoneFitTheMeal() {
        let summary = homeSummary([recipe("Pancakes", mealTypes: [.breakfast]), recipe("Untagged")])
        let pool = summary.surprisePool(for: .dinner)
        #expect(pool.mealType == nil)
        #expect(Set(pool.recipes.map(\.title)) == ["Pancakes", "Untagged"])
    }

    @Test func surpriseKeepsTheOnlyFittingRecipeEvenWhenItWasJustOpened() {
        let summary = homeSummary([
            recipe("Only dinner", mealTypes: [.dinner], openedDaysAgo: 0),
            recipe("Untagged"),
        ])
        let pool = summary.surprisePool(for: .dinner)
        #expect(pool.mealType == .dinner)
        #expect(pool.recipes.map(\.title) == ["Only dinner"])
    }

    @Test func surpriseSkipsTheContinueRecipeAmongFittingOnes() {
        let summary = homeSummary([
            recipe("Last dinner", mealTypes: [.dinner], openedDaysAgo: 0),
            recipe("Other dinner", mealTypes: [.dinner]),
            recipe("Untagged"),
        ])
        #expect(summary.surprisePool(for: .dinner).recipes.map(\.title) == ["Other dinner"])
    }

    @Test func surpriseNeedsAtLeastTwoRecipes() {
        #expect(!homeSummary([recipe("Only one")]).canSurprise)
        #expect(!homeSummary([]).canSurprise)
    }

    // MARK: Meal row

    @Test func mealRowShowsRecipesForTheMealMostRecentlyOpenedFirst() {
        let summary = homeSummary([
            recipe("Soup", mealTypes: [.dinner], openedDaysAgo: 5),
            recipe("Curry", mealTypes: [.lunch, .dinner], openedDaysAgo: 1),
            recipe("Toast", mealTypes: [.breakfast], openedDaysAgo: 0),
            recipe("Risotto", mealTypes: [.dinner]),
        ])
        #expect(summary.recipes(for: .dinner).map(\.title) == ["Curry", "Soup", "Risotto"])
        #expect(summary.recipes(for: .snack).isEmpty)
    }

    @Test func mealRowStopsAtTheLimit() {
        let recipes = (0..<10).map { recipe("Dinner \($0)", mealTypes: [.dinner]) }
        #expect(homeSummary(recipes).recipes(for: .dinner).count == HomeSummary.rowLimit)
    }

    // MARK: Rediscover

    @Test func rediscoverShowsRecipesNotOpenedForAMonthLongestForgottenFirst() {
        let summary = homeSummary([
            recipe("Last week", openedDaysAgo: 7),
            recipe("Two months", openedDaysAgo: 60),
            recipe("Six weeks", openedDaysAgo: 42),
            recipe("Never opened, old", createdDaysAgo: 50),
        ])
        #expect(summary.rediscover.map(\.title) == ["Two months", "Never opened, old", "Six weeks"])
    }

    @Test func rediscoverLeavesOutNewRecipesThatWerentOpenedYet() {
        let summary = homeSummary([recipe("Just added", createdDaysAgo: 2)])
        #expect(summary.rediscover.isEmpty)
    }

    @Test func rediscoverStartsAfterThirtyDays() {
        let summary = homeSummary([
            recipe("29 days", openedDaysAgo: 29),
            recipe("31 days", openedDaysAgo: 31),
        ])
        #expect(summary.rediscover.map(\.title) == ["31 days"])
    }

    // MARK: Browse by meal

    @Test func countsRecipesForEachMeal() {
        let summary = homeSummary([
            recipe("Pancakes", mealTypes: [.breakfast, .dessert]),
            recipe("Toast", mealTypes: [.breakfast]),
            recipe("Untagged"),
        ])
        #expect(summary.mealCounts == [.breakfast: 2, .dessert: 1])
    }
}
