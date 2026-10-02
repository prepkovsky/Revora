import Foundation
import Testing
@testable import Revora

struct RecipeFilterTests {
    private static let day: TimeInterval = 24 * 60 * 60
    private let now = Date(timeIntervalSince1970: 100 * day)

    private func daysAgo(_ days: Double) -> Date {
        now.addingTimeInterval(-days * Self.day)
    }

    private func recipe(
        _ title: String,
        isFavorite: Bool = false,
        updatedDaysAgo: Double = 30,
        openedDaysAgo: Double? = nil
    ) -> Recipe {
        Recipe(
            id: title,
            title: title,
            ingredients: [],
            steps: [],
            isFavorite: isFavorite,
            createdAt: daysAgo(60),
            updatedAt: daysAgo(updatedDaysAgo),
            lastOpenedAt: openedDaysAgo.map(daysAgo)
        )
    }

    private var recipes: [Recipe] {
        [
            recipe("Pancakes", isFavorite: true, openedDaysAgo: 2),
            recipe("Crème Brûlée", updatedDaysAgo: 1),
            recipe("Apple Pancakes", isFavorite: true, openedDaysAgo: 0.5),
            recipe("Banana Bread", openedDaysAgo: 5),
        ]
    }

    private func titles(_ filter: RecipeFilter, search: String = "") -> [String] {
        filter.apply(to: recipes, searchText: search, now: now).map(\.title)
    }

    @Test func recentShowsRecipesUsedInTheLastThreeDaysNewestFirst() {
        #expect(titles(.recent) == ["Apple Pancakes", "Crème Brûlée", "Pancakes"])
    }

    @Test func recentKeepsARecipeUntilExactlyThreeDaysHavePassed() {
        let edge = [recipe("Just in", openedDaysAgo: 3), recipe("Just out", openedDaysAgo: 3.01)]
        #expect(RecipeFilter.recent.apply(to: edge, searchText: "", now: now).map(\.title) == ["Just in"])
    }

    @Test func allSortsByTitle() {
        #expect(titles(.all) == ["Apple Pancakes", "Banana Bread", "Crème Brûlée", "Pancakes"])
    }

    @Test func favoritesKeepsOnlyFavoritesByTitle() {
        #expect(titles(.favorites) == ["Apple Pancakes", "Pancakes"])
    }

    @Test func searchMatchesPartOfTheTitle() {
        #expect(titles(.all, search: "pancake") == ["Apple Pancakes", "Pancakes"])
    }

    @Test func searchIgnoresCaseAndAccents() {
        #expect(titles(.all, search: "CREME brulee") == ["Crème Brûlée"])
    }

    @Test func searchIgnoresSurroundingSpaces() {
        #expect(titles(.all, search: "  apple ") == ["Apple Pancakes"])
        #expect(titles(.all, search: "   ") == titles(.all))
    }

    @Test func searchStaysWithinTheSegment() {
        #expect(titles(.favorites, search: "crème").isEmpty)
        #expect(titles(.recent, search: "bread").isEmpty)
        #expect(titles(.recent, search: "pancakes") == ["Apple Pancakes", "Pancakes"])
    }
}
