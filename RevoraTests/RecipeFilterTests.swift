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
        mealTypes: [MealType] = [],
        isFavorite: Bool = false,
        updatedDaysAgo: Double = 30,
        openedDaysAgo: Double? = nil
    ) -> Recipe {
        Recipe(
            id: title,
            title: title,
            mealTypes: mealTypes,
            isFavorite: isFavorite,
            createdAt: daysAgo(60),
            updatedAt: daysAgo(updatedDaysAgo),
            lastOpenedAt: openedDaysAgo.map(daysAgo)
        )
    }

    private var recipes: [Recipe] {
        [
            recipe("Pancakes", mealTypes: [.breakfast], isFavorite: true, openedDaysAgo: 2),
            recipe("Crème Brûlée", mealTypes: [.dessert], updatedDaysAgo: 1),
            recipe("Apple Pancakes", mealTypes: [.breakfast, .dessert], isFavorite: true, openedDaysAgo: 0.5),
            recipe("Banana Bread", openedDaysAgo: 5),
        ]
    }

    private func titles(_ filter: RecipeFilter, mealType: MealType? = nil, search: String = "") -> [String] {
        filter.apply(to: recipes, mealType: mealType, searchText: search, now: now).map(\.title)
    }

    @Test func recentShowsRecipesOpenedInTheLastThreeDaysNewestFirst() {
        #expect(titles(.recent) == ["Apple Pancakes", "Pancakes"])
    }

    @Test func recentIgnoresCreatingAndEditing() {
        let recipes = [recipe("Just edited", updatedDaysAgo: 0), recipe("Opened long ago", updatedDaysAgo: 0, openedDaysAgo: 10)]
        #expect(RecipeFilter.recent.apply(to: recipes, searchText: "", now: now).isEmpty)
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

    @Test func mealTypeKeepsOnlyRecipesForThatMeal() {
        #expect(titles(.all, mealType: .dessert) == ["Apple Pancakes", "Crème Brûlée"])
        #expect(titles(.all, mealType: .drink).isEmpty)
    }

    @Test func mealTypeCombinesWithTheSegmentAndSearch() {
        #expect(titles(.favorites, mealType: .dessert) == ["Apple Pancakes"])
        #expect(titles(.recent, mealType: .breakfast) == ["Apple Pancakes", "Pancakes"])
        #expect(titles(.all, mealType: .breakfast, search: "apple") == ["Apple Pancakes"])
    }

    @Test func searchStaysWithinTheSegment() {
        #expect(titles(.favorites, search: "crème").isEmpty)
        #expect(titles(.recent, search: "bread").isEmpty)
        #expect(titles(.recent, search: "pancakes") == ["Apple Pancakes", "Pancakes"])
    }
}
