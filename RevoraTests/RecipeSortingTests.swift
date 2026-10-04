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

    @Test func recentPutsLatestOpenedFirst() {
        let recipes = [
            recipe("Apple Pie", created: 100, opened: 300),
            recipe("Banana Bread", created: 50, updated: 900, opened: 200),
            recipe("Pancakes", created: 200, opened: 400),
        ]
        #expect(recipes.sortedByRecent().map(\.title) == ["Pancakes", "Apple Pie", "Banana Bread"])
    }

    @Test func recentPutsNeverOpenedLast() {
        let recipes = [
            recipe("Never opened", created: 900, updated: 900),
            recipe("Opened", created: 100, opened: 200),
        ]
        #expect(recipes.sortedByRecent().map(\.title) == ["Opened", "Never opened"])
    }

    @Test func recentTiesGoToTheNewerRecipe() {
        let recipes = [
            recipe("Older", created: 100, opened: 500),
            recipe("Newer", created: 200, opened: 500),
        ]
        #expect(recipes.sortedByRecent().map(\.title) == ["Newer", "Older"])
    }
}
