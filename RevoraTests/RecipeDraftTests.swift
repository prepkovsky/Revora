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
        #expect(draft.trimmedIngredientSections == RecipeSection.untitled([
            Ingredient(name: "Flour", quantity: "200 g"),
            Ingredient(name: "Eggs", quantity: "2"),
        ]))
    }

    @Test func blankIngredientRowsAreDropped() {
        let draft = RecipeDraft(ingredients: [
            .init(),
            .init(quantity: " ", name: " \t"),
            .init(quantity: "", name: "Salt"),
        ])
        #expect(draft.trimmedIngredientSections == RecipeSection.untitled([Ingredient(name: "Salt", quantity: "")]))
    }

    @Test func quantityWithoutNameIsKept() {
        let draft = RecipeDraft(ingredients: [.init(quantity: "200 g", name: "")])
        #expect(draft.trimmedIngredientSections == RecipeSection.untitled([Ingredient(name: "", quantity: "200 g")]))
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
        #expect(draft.trimmedStepSections == RecipeSection.untitled([Step(text: "Whisk everything."), Step(text: "Fry in a hot pan.")]))
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
        ingredientSections: [
            RecipeSection(title: nil, items: [Ingredient(name: "Flour", quantity: "200 g")]),
            RecipeSection(title: "To serve", items: [Ingredient(name: "Salt", quantity: "")]),
        ],
        stepSections: [
            RecipeSection(title: "Batter", items: [Step(text: "Whisk together:", bullets: ["flour", "milk"])]),
            RecipeSection(title: "Cook", items: [Step(text: "Fry in a hot pan.")]),
        ],
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
        #expect(draft.trimmedIngredientSections == savedRecipe.ingredientSections)
        #expect(draft.trimmedStepSections == savedRecipe.stepSections)
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
        #expect(edited.ingredientSections == savedRecipe.ingredientSections)
        #expect(edited.steps == savedRecipe.steps + [Step(text: "Serve warm.")])
        #expect(edited.stepSections.last?.title == "Cook")
        #expect(edited.photoID == nil)
        #expect(edited.id == savedRecipe.id)
        #expect(edited.isFavorite)
        #expect(edited.createdAt == savedRecipe.createdAt)
        #expect(edited.lastOpenedAt == savedRecipe.lastOpenedAt)
    }

    // MARK: Sections

    @Test func groupsIngredientsUnderTheSectionAbove() {
        let draft = RecipeDraft(ingredients: [
            .init(quantity: "1", name: "Lemon"),
            .init(isSection: true, name: " For the dough "),
            .init(quantity: "300 g", name: "Flour"),
            .init(isSection: true, name: "For the filling"),
            .init(quantity: "200 g", name: "Spinach"),
        ])
        #expect(draft.trimmedIngredientSections == [
            RecipeSection(title: nil, items: [Ingredient(name: "Lemon", quantity: "1")]),
            RecipeSection(title: "For the dough", items: [Ingredient(name: "Flour", quantity: "300 g")]),
            RecipeSection(title: "For the filling", items: [Ingredient(name: "Spinach", quantity: "200 g")]),
        ])
    }

    @Test func listStartingWithASectionHasNoUntitledOne() {
        let draft = RecipeDraft(steps: [
            .init(isSection: true, text: "Make the dough"),
            .init(text: "Mix."),
        ])
        #expect(draft.trimmedStepSections == [RecipeSection(title: "Make the dough", items: [Step(text: "Mix.")])])
    }

    @Test func blankSectionJoinsItsStepsToTheSectionAbove() {
        let draft = RecipeDraft(steps: [
            .init(isSection: true, text: "Make the dough"),
            .init(text: "Mix."),
            .init(isSection: true, text: "  "),
            .init(text: "Knead."),
        ])
        #expect(draft.trimmedStepSections == [
            RecipeSection(title: "Make the dough", items: [Step(text: "Mix."), Step(text: "Knead.")]),
        ])
    }

    @Test func namedSectionWithoutItemsIsKept() {
        let draft = RecipeDraft(ingredients: [.init(isSection: true, name: "For the sauce"), .init()])
        #expect(draft.trimmedIngredientSections == [RecipeSection(title: "For the sauce", items: [])])
    }

    @Test func blankSectionIsNoChange() {
        let draft = RecipeDraft(steps: [.init(isSection: true, text: " ")])
        #expect(!draft.hasChanges(from: RecipeDraft()))
    }

    @Test func movingAnItemToAnotherSectionCountsAsChange() {
        let original = RecipeDraft(recipe: savedRecipe)
        var draft = original
        // Moves "Fry in a hot pan." above the "Cook" section, into "Batter".
        draft.steps.insert(draft.steps.remove(at: 3), at: 2)
        #expect(draft.hasChanges(from: original))
        #expect(draft.trimmedStepSections.first?.items.count == 2)
    }

    @Test func stepNumbersStartAgainInEachSection() {
        let draft = RecipeDraft(steps: [
            .init(text: "Preheat the oven."),
            .init(isSection: true, text: "Make the dough"),
            .init(text: "Mix."),
            .init(text: "Knead."),
            .init(isSection: true, text: "Bake"),
            .init(text: "Bake for 40 minutes."),
        ])
        #expect(draft.steps.map { draft.stepNumbers[$0.id] } == [1, 1, 1, 2, 2, 1])
    }

    // MARK: Bullet points

    @Test func bulletPointsAreTrimmedWithoutBlanks() {
        let draft = RecipeDraft(steps: [
            .init(text: "Stir in:", bullets: [.init(text: " spinach "), .init(text: " "), .init(text: "nutmeg")]),
        ])
        #expect(draft.trimmedStepSections == RecipeSection.untitled([Step(text: "Stir in:", bullets: ["spinach", "nutmeg"])]))
    }

    @Test func stepWithOnlyBulletPointsIsKept() {
        let draft = RecipeDraft(steps: [.init(text: " ", bullets: [.init(text: "Salt")])])
        #expect(draft.trimmedStepSections == RecipeSection.untitled([Step(text: "", bullets: ["Salt"])]))
    }

    @Test func stepWithOnlyBlankBulletPointsIsBlank() {
        let step = RecipeDraft.StepRow(text: " ", bullets: [.init(text: ""), .init(text: " ")])
        #expect(step.isBlank)
        #expect(RecipeDraft(steps: [step]).trimmedStepSections.isEmpty)
    }

    @Test func addingABulletPointCountsAsChange() {
        let original = RecipeDraft(recipe: savedRecipe)
        var draft = original
        draft.steps[1].bullets.append(.init(text: "eggs"))
        #expect(draft.hasChanges(from: original))
    }

    @Test func bulletPointLineBreaksAreRemoved() {
        var bullet = RecipeDraft.BulletRow(text: "flour\n")
        let removed = bullet.removeLineBreaks()
        #expect(removed)
        #expect(bullet.text == "flour")
    }

    @Test func prefillsSectionsAndBulletPointsAsRows() {
        let draft = RecipeDraft(recipe: savedRecipe)
        #expect(draft.ingredients.map(\.isSection) == [false, true, false])
        #expect(draft.ingredients[1].name == "To serve")
        #expect(draft.steps.map(\.isSection) == [true, false, true, false])
        #expect(draft.steps[1].bullets.map(\.text) == ["flour", "milk"])
    }
}
