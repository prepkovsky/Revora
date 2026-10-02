import Foundation
import Testing
@testable import Revora

struct RecipeSortingTests {
    private func recipe(
        _ title: String,
        id: String? = nil,
        created: TimeInterval = 0,
        updated: TimeInterval? = nil,
        opened: TimeInterval? = nil
    ) -> Recipe {
        Recipe(
            id: id ?? title,
            title: title,
            ingredients: [],
            steps: [],
            createdAt: Date(timeIntervalSince1970: created),
            updatedAt: Date(timeIntervalSince1970: updated ?? created),
            lastOpenedAt: opened.map(Date.init(timeIntervalSince1970:))
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

    @Test func recentPutsLatestUseFirst() {
        let recipes = [
            recipe("Apple Pie", created: 100, opened: 400),
            recipe("Banana Bread", created: 50, updated: 300),
            recipe("Pancakes", created: 200),
        ]
        #expect(recipes.sortedByRecent().map(\.title) == ["Apple Pie", "Banana Bread", "Pancakes"])
    }

    @Test func lastUsedIsTheLaterOfOpenedAndUpdated() {
        #expect(recipe("Opened later", updated: 100, opened: 200).lastUsedAt == Date(timeIntervalSince1970: 200))
        #expect(recipe("Edited later", updated: 300, opened: 200).lastUsedAt == Date(timeIntervalSince1970: 300))
        #expect(recipe("Never opened", updated: 100).lastUsedAt == Date(timeIntervalSince1970: 100))
    }

    @Test func recentTiesGoToTheNewerRecipe() {
        let recipes = [
            recipe("Older", created: 100, updated: 500),
            recipe("Newer", created: 200, updated: 500),
        ]
        #expect(recipes.sortedByRecent().map(\.title) == ["Newer", "Older"])
    }
}
