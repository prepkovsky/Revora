import Foundation
import Testing
import UIKit
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

    @Test func stepsAreTrimmedInOrderWithoutBlanks() {
        let draft = RecipeDraft(steps: [
            .init(text: " Whisk everything. "),
            .init(text: " \n"),
            .init(text: "Fry in a hot pan."),
        ])
        #expect(draft.trimmedSteps == ["Whisk everything.", "Fry in a hot pan."])
    }

    @Test(arguments: [
        ("Whisk\n", "Whisk"),
        ("\nWhisk", "Whisk"),
        ("Whisk\nthen fry", "Whisk then fry"),
        ("Whisk\r\n", "Whisk"),
    ])
    func stepLineBreaksAreRemoved(text: String, expected: String) {
        var step = RecipeDraft.StepRow(text: text)
        let removed = step.removeLineBreaks()
        #expect(removed)
        #expect(step.text == expected)
    }

    @Test func stepWithoutLineBreaksIsUnchanged() {
        var step = RecipeDraft.StepRow(text: "Whisk everything.")
        let removed = step.removeLineBreaks()
        #expect(!removed)
        #expect(step.text == "Whisk everything.")
    }

    @Test func emptyDraftHasNoChanges() {
        let draft = RecipeDraft(
            title: "  ",
            ingredients: [.init()],
            steps: [.init(text: "\n")]
        )
        #expect(!draft.hasChanges(from: RecipeDraft()))
    }

    @Test(arguments: [
        RecipeDraft(title: "Pancakes"),
        RecipeDraft(ingredients: [.init(quantity: "2", name: "")]),
        RecipeDraft(steps: [.init(text: "Whisk")]),
        RecipeDraft(mealTypes: [.dinner]),
    ])
    func contentCountsAsChanges(_ draft: RecipeDraft) {
        #expect(draft.hasChanges(from: RecipeDraft()))
    }

    private func pickedPhoto() -> RecipeDraft.Photo {
        .picked(RecipeDraft.PickedPhoto(prepared: PreparedPhoto(full: Data(), thumbnail: Data()), preview: UIImage()))
    }

    @Test func pickedPhotoCountsAsChange() {
        #expect(RecipeDraft(photo: pickedPhoto()).hasChanges(from: RecipeDraft()))
    }

    @Test func removedPhotoCountsAsChange() {
        let original = RecipeDraft(photo: pickedPhoto())
        var draft = original
        draft.photo = nil
        #expect(draft.hasChanges(from: original))
    }

    @Test func samePhotoIsNoChange() {
        let original = RecipeDraft(photo: pickedPhoto())
        #expect(!original.hasChanges(from: original))
    }

    @Test func differentPhotoCountsAsChange() {
        let original = RecipeDraft(photo: pickedPhoto())
        var draft = original
        draft.photo = pickedPhoto()
        #expect(draft.hasChanges(from: original))
    }

    private let savedRecipe = Recipe(
        id: "recipe-1",
        title: "Pancakes",
        ingredients: [Ingredient(name: "Flour", quantity: "200 g"), Ingredient(name: "Salt", quantity: "")],
        steps: ["Whisk everything together.", "Fry in a hot pan."],
        mealTypes: [.breakfast],
        photoID: "photo-1",
        isFavorite: true,
        createdAt: Date(timeIntervalSince1970: 100),
        updatedAt: Date(timeIntervalSince1970: 200),
        lastOpenedAt: Date(timeIntervalSince1970: 300)
    )

    @Test func prefillsFromRecipe() {
        let draft = RecipeDraft(recipe: savedRecipe)
        #expect(draft.trimmedTitle == "Pancakes")
        #expect(draft.trimmedIngredients == savedRecipe.ingredients)
        #expect(draft.trimmedSteps == savedRecipe.steps)
        #expect(draft.photo == .saved(photoID: "photo-1", recipeID: "recipe-1"))
        #expect(draft.mealTypes == [.breakfast])
    }

    @Test func unpickingAMealTypeCountsAsChange() {
        let original = RecipeDraft(recipe: savedRecipe)
        var draft = original
        draft.mealTypes = []
        #expect(draft.hasChanges(from: original))
    }

    @Test func savesMealTypesInDisplayOrder() {
        var draft = RecipeDraft(recipe: savedRecipe)
        draft.mealTypes = [.dessert, .snack, .breakfast]
        #expect(draft.applied(to: savedRecipe, photoID: nil).mealTypes == [.breakfast, .snack, .dessert])
    }

    @Test func untouchedRecipeHasNoChanges() {
        let draft = RecipeDraft(recipe: savedRecipe)
        #expect(!draft.hasChanges(from: RecipeDraft(recipe: savedRecipe)))
    }

    @Test func removingSavedPhotoCountsAsChange() {
        let original = RecipeDraft(recipe: savedRecipe)
        var draft = original
        draft.photo = nil
        #expect(draft.hasChanges(from: original))
    }

    @Test func replacingSavedPhotoCountsAsChange() {
        let original = RecipeDraft(recipe: savedRecipe)
        var draft = original
        draft.photo = pickedPhoto()
        #expect(draft.hasChanges(from: original))
    }

    @Test func appliesEditsAndKeepsEverythingElse() {
        var draft = RecipeDraft(recipe: savedRecipe)
        draft.title = "  Fluffy Pancakes "
        draft.steps.append(.init(text: "Serve warm."))

        let edited = draft.applied(to: savedRecipe, photoID: nil)
        #expect(edited.title == "Fluffy Pancakes")
        #expect(edited.ingredients == savedRecipe.ingredients)
        #expect(edited.steps == savedRecipe.steps + ["Serve warm."])
        #expect(edited.photoID == nil)
        #expect(edited.id == savedRecipe.id)
        #expect(edited.isFavorite)
        #expect(edited.createdAt == savedRecipe.createdAt)
        #expect(edited.lastOpenedAt == savedRecipe.lastOpenedAt)
    }
}
