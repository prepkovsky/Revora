import Foundation
import Testing
@testable import Revora

struct HomeSummaryTests {
    private static let day: TimeInterval = 24 * 60 * 60
    private let now = Date(timeIntervalSince1970: 100 * day)

    private func recipe(_ title: String, isFavorite: Bool = false, openedDaysAgo: Double? = nil) -> Recipe {
        Recipe(
            id: title,
            title: title,
            ingredients: [],
            steps: [],
            isFavorite: isFavorite,
            createdAt: now.addingTimeInterval(-60 * Self.day),
            updatedAt: now,
            lastOpenedAt: openedDaysAgo.map { now.addingTimeInterval(-$0 * Self.day) }
        )
    }

    /// Always picks the first candidate, so the surprise is predictable in tests.
    private struct FirstPick: RandomNumberGenerator {
        mutating func next() -> UInt64 { 0 }
    }

    @Test func continueShowsTheLastOpenedRecipeHoweverLongAgo() {
        let summary = HomeSummary(recipes: [recipe("Soup", openedDaysAgo: 40), recipe("Pie", openedDaysAgo: 90), recipe("New")])
        #expect(summary.continueRecipe?.title == "Soup")
    }

    @Test func continueIsHiddenUntilARecipeIsOpened() {
        #expect(HomeSummary(recipes: [recipe("New"), recipe("Newer")]).continueRecipe == nil)
    }

    @Test func favoritesAreMostRecentlyOpenedFirst() {
        let summary = HomeSummary(recipes: [
            recipe("Never opened", isFavorite: true),
            recipe("Yesterday", isFavorite: true, openedDaysAgo: 1),
            recipe("Not a favorite", openedDaysAgo: 0),
            recipe("Last week", isFavorite: true, openedDaysAgo: 7),
        ])
        #expect(summary.favorites.map(\.title) == ["Yesterday", "Last week", "Never opened"])
    }

    @Test func favoritesStopAtTheLimit() {
        let recipes = (0..<10).map { recipe("Favorite \($0)", isFavorite: true, openedDaysAgo: Double($0)) }
        let summary = HomeSummary(recipes: recipes)
        #expect(summary.favorites.count == HomeSummary.favoritesLimit)
        #expect(summary.favorites.first?.title == "Favorite 0")
    }

    @Test func surpriseSkipsTheContinueRecipe() {
        var generator = FirstPick()
        let summary = HomeSummary(recipes: [recipe("Last opened", openedDaysAgo: 0), recipe("Other")])
        #expect(summary.canSurprise)
        #expect(summary.surpriseRecipe(using: &generator)?.title == "Other")
    }

    @Test func surpriseNeedsAtLeastTwoRecipes() {
        #expect(!HomeSummary(recipes: [recipe("Only one")]).canSurprise)
        #expect(!HomeSummary(recipes: []).canSurprise)
    }
}
