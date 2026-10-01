import Foundation
import Testing
@testable import Revora

struct RecipeSortingTests {
    private func recipe(_ title: String, id: String? = nil, created: TimeInterval = 0) -> Recipe {
        Recipe(
            id: id ?? title,
            title: title,
            ingredients: [],
            steps: [],
            createdAt: Date(timeIntervalSince1970: created),
            updatedAt: Date(timeIntervalSince1970: created)
        )
    }

    private func titles(_ recipes: [Recipe]) -> [String] {
        recipes.sortedByTitle().map(\.title)
    }

    @Test func sortsAlphabeticallyIgnoringCase() {
        let recipes = [recipe("pancakes"), recipe("Banana Bread"), recipe("omelette"), recipe("Apple Pie")]
        #expect(titles(recipes) == ["Apple Pie", "Banana Bread", "omelette", "pancakes"])
    }

    @Test func sortsNumbersByValue() {
        let recipes = [recipe("Soup 10"), recipe("Soup 2"), recipe("Soup 1")]
        #expect(titles(recipes) == ["Soup 1", "Soup 2", "Soup 10"])
    }

    @Test func sameTitlesKeepOldestFirst() {
        let recipes = [
            recipe("Pancakes", id: "newer", created: 200),
            recipe("Pancakes", id: "older", created: 100),
        ]
        #expect(recipes.sortedByTitle().map(\.id) == ["older", "newer"])
    }
}
