import Testing
@testable import Revora

struct RecipeDraftTests {
    @Test func newDraftCantBeSaved() {
        #expect(!RecipeDraft().canSave)
    }

    @Test(arguments: ["", " ", "  \n\t"])
    func blankTitleCantBeSaved(_ title: String) {
        #expect(!RecipeDraft(title: title).canSave)
    }

    @Test func titleIsTrimmed() {
        let draft = RecipeDraft(title: "  Banana Bread \n")
        #expect(draft.canSave)
        #expect(draft.trimmedTitle == "Banana Bread")
    }

    @Test func ingredientsAreTrimmedInOrder() {
        let draft = RecipeDraft(ingredients: [
            .init(quantity: " 200 g ", name: "Flour\n"),
            .init(quantity: "2", name: "  Eggs"),
        ])
        #expect(draft.trimmedIngredients == [
            Ingredient(name: "Flour", quantity: "200 g"),
            Ingredient(name: "Eggs", quantity: "2"),
        ])
    }

    @Test func blankIngredientRowsAreDropped() {
        let draft = RecipeDraft(ingredients: [
            .init(),
            .init(quantity: " ", name: " \t"),
            .init(quantity: "", name: "Salt"),
        ])
        #expect(draft.trimmedIngredients == [Ingredient(name: "Salt", quantity: "")])
    }

    @Test func quantityWithoutNameIsKept() {
        let draft = RecipeDraft(ingredients: [.init(quantity: "200 g", name: "")])
        #expect(draft.trimmedIngredients == [Ingredient(name: "", quantity: "200 g")])
    }

    @Test func ingredientsDontAffectSaving() {
        #expect(!RecipeDraft(ingredients: [.init(quantity: "2", name: "Eggs")]).canSave)
        #expect(RecipeDraft(title: "Omelette").canSave)
    }
}
