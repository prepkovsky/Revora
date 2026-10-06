import Foundation
import Testing
@testable import Revora

struct ScannedRecipeTests {
    /// Like the `scanRecipe` function's `recipe`: untitled sections leave `title` out.
    private let json = """
        {
          "title": "Apple Pie",
          "ingredientSections": [
            { "items": [{ "name": "butter", "quantity": "200 g" }] },
            { "title": "Filling", "items": [{ "name": "apples", "quantity": "4" }, { "name": "salt", "quantity": "" }] }
          ],
          "stepSections": [
            { "title": "Dough", "items": [{ "text": "Rub the butter into the flour.", "bullets": [] }] },
            { "title": "Bake", "items": [{ "text": "Fill the pie.", "bullets": ["apples", "cinnamon"] }] }
          ],
          "mealTypes": ["snack", "dessert", "brunch"]
        }
        """

    private func decoded() throws -> ScannedRecipe {
        try JSONDecoder().decode(ScannedRecipe.self, from: Data(json.utf8))
    }

    @Test func decodesTheFunctionsReply() throws {
        let recipe = try decoded()
        #expect(recipe.title == "Apple Pie")
        #expect(recipe.ingredientSections == [
            RecipeSection(title: nil, items: [Ingredient(name: "butter", quantity: "200 g")]),
            RecipeSection(title: "Filling", items: [Ingredient(name: "apples", quantity: "4"), Ingredient(name: "salt", quantity: "")]),
        ])
        #expect(recipe.stepSections == [
            RecipeSection(title: "Dough", items: [Step(text: "Rub the butter into the flour.")]),
            RecipeSection(title: "Bake", items: [Step(text: "Fill the pie.", bullets: ["apples", "cinnamon"])]),
        ])
    }

    @Test func skipsUnknownMealsAndKeepsTheAppsOrder() throws {
        #expect(try decoded().mealTypes == [.snack, .dessert])
        let reversed = json.replacingOccurrences(of: #"["snack", "dessert", "brunch"]"#, with: #"["dessert", "snack"]"#)
        #expect(try JSONDecoder().decode(ScannedRecipe.self, from: Data(reversed.utf8)).mealTypes == [.snack, .dessert])
    }

    @Test func draftHasSectionRowsWhereTheRecipeHasHeadings() throws {
        let draft = RecipeDraft(scanned: try decoded())
        #expect(draft.title == "Apple Pie")
        #expect(draft.ingredients.map(\.isSection) == [false, true, false, false])
        #expect(draft.ingredients.map(\.name) == ["butter", "Filling", "apples", "salt"])
        #expect(draft.steps.map(\.isSection) == [true, false, true, false])
        #expect(draft.steps[3].bullets.map(\.text) == ["apples", "cinnamon"])
        #expect(draft.mealTypes == [.snack, .dessert])
    }

    @Test func draftSavesTheScannedRecipeUnchanged() throws {
        let recipe = try decoded()
        let draft = RecipeDraft(scanned: recipe)
        #expect(draft.trimmedTitle == recipe.title)
        #expect(draft.trimmedIngredientSections == recipe.ingredientSections)
        #expect(draft.trimmedStepSections == recipe.stepSections)
    }

    @Test func draftIsANewRecipeWithoutACoverPhoto() throws {
        let draft = RecipeDraft(scanned: try decoded())
        #expect(draft.photo == nil)
        // So Cancel asks before throwing the scan away.
        #expect(draft.hasChanges(from: RecipeDraft()))
    }

    @Test func draftWithoutATitleCantBeSavedYet() {
        let draft = RecipeDraft(scanned: ScannedRecipe(title: "", stepSections: RecipeSection.untitled([Step(text: "Mix.")])))
        #expect(!draft.canSave)
        #expect(draft.steps.map(\.text) == ["Mix."])
    }
}
