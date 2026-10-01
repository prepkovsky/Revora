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
    ])
    func contentCountsAsChanges(_ draft: RecipeDraft) {
        #expect(draft.hasChanges(from: RecipeDraft()))
    }

    private func pickedPhoto() -> RecipeDraft.PickedPhoto {
        RecipeDraft.PickedPhoto(prepared: PreparedPhoto(full: Data(), thumbnail: Data()), preview: UIImage())
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
}
