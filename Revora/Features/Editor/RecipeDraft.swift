import UIKit

/// What the editor holds while people type, before it's saved as a `Recipe`.
///
/// Ingredients and steps are each one flat list, with section rows between the items, so an
/// item can be dragged from one section to another. Saving groups them into `RecipeSection`s.
struct RecipeDraft: Equatable {
    /// An ingredient being edited, or the name of the section that the ingredients below it
    /// belong to. The ID keeps rows apart while they're added, moved and deleted.
    struct IngredientRow: Identifiable, Equatable {
        let id = UUID()
        var isSection = false
        var quantity = ""
        /// The ingredient, or the section's name.
        var name = ""

        var isBlank: Bool {
            trimmed(quantity).isEmpty && trimmed(name).isEmpty
        }

        /// Like a step, Return moves on to the next row instead of starting a new line.
        mutating func removeLineBreaks() -> Bool {
            name.removeLineBreaks()
        }
    }

    /// A step being edited, or the name of the section that the steps below it belong to.
    struct StepRow: Identifiable, Equatable {
        let id = UUID()
        var isSection = false
        /// The step, or the section's name.
        var text = ""
        var bullets: [BulletRow] = []

        var isBlank: Bool {
            trimmed(text).isEmpty && bullets.allSatisfy(\.isBlank)
        }

        /// Each step is one paragraph, so Return moves on instead of starting a new line.
        /// Returns whether there was a line break to remove.
        mutating func removeLineBreaks() -> Bool {
            text.removeLineBreaks()
        }
    }

    /// A bullet point under a step.
    struct BulletRow: Identifiable, Equatable {
        let id = UUID()
        var text = ""

        var isBlank: Bool {
            trimmed(text).isEmpty
        }

        /// Like a step, Return moves on to the next bullet point instead of starting a new line.
        mutating func removeLineBreaks() -> Bool {
            text.removeLineBreaks()
        }
    }

    /// A cover photo picked in the editor and already shrunk, so saving is quick.
    struct PickedPhoto: Identifiable, Equatable {
        let id = UUID()
        let prepared: PreparedPhoto
        let preview: UIImage

        /// By ID, so checking for changes never compares the image data.
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }

    enum Photo: Equatable {
        /// Already stored with the recipe being edited.
        case saved(photoID: String, recipeID: Recipe.ID)
        case picked(PickedPhoto)
    }

    var title = ""
    var ingredients: [IngredientRow] = []
    var steps: [StepRow] = []
    var photo: Photo?
    var mealTypes: Set<MealType> = []

    var trimmedTitle: String {
        trimmed(title)
    }

    /// Blank rows are dropped. A row with only a quantity is kept, so nothing people typed is lost.
    var trimmedIngredientSections: [RecipeSection<Ingredient>] {
        sections(from: ingredients, title: { $0.isSection ? $0.name : nil }) { row in
            row.isBlank ? nil : Ingredient(name: trimmed(row.name), quantity: trimmed(row.quantity))
        }
    }

    /// Blank steps and bullet points are dropped. A step with only bullet points is kept.
    var trimmedStepSections: [RecipeSection<Step>] {
        sections(from: steps, title: { $0.isSection ? $0.text : nil }) { row in
            row.isBlank ? nil : Step(
                text: trimmed(row.text),
                bullets: row.bullets.filter { !$0.isBlank }.map { trimmed($0.text) }
            )
        }
    }

    /// The number the editor shows before each row of the step list, like the recipe page:
    /// sections count 1, 2, 3…, and the steps under each section start again at 1.
    var stepNumbers: [StepRow.ID: Int] {
        var numbers: [StepRow.ID: Int] = [:]
        var section = 0
        var step = 0
        for row in steps {
            if row.isSection {
                section += 1
                step = 0
                numbers[row.id] = section
            } else {
                step += 1
                numbers[row.id] = step
            }
        }
        return numbers
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty
    }

    /// Compares what would be saved, so blank rows and stray spaces don't count as changes.
    func hasChanges(from original: RecipeDraft) -> Bool {
        trimmedTitle != original.trimmedTitle
            || trimmedIngredientSections != original.trimmedIngredientSections
            || trimmedStepSections != original.trimmedStepSections
            || photo != original.photo
            || mealTypes != original.mealTypes
    }
}

extension RecipeDraft {
    /// Prefilled for editing a saved recipe.
    init(recipe: Recipe) {
        title = recipe.title
        ingredients = rows(
            from: recipe.ingredientSections,
            section: { IngredientRow(isSection: true, name: $0) },
            item: { IngredientRow(quantity: $0.quantity, name: $0.name) }
        )
        steps = rows(
            from: recipe.stepSections,
            section: { StepRow(isSection: true, text: $0) },
            item: { StepRow(text: $0.text, bullets: $0.bullets.map { BulletRow(text: $0) }) }
        )
        photo = recipe.photoID.map { .saved(photoID: $0, recipeID: recipe.id) }
        mealTypes = Set(recipe.mealTypes)
    }

    /// The recipe with this draft's edits. Fields the editor doesn't show, like favorites, stay as they are.
    func applied(to recipe: Recipe, photoID: String?) -> Recipe {
        var recipe = recipe
        recipe.title = trimmedTitle
        recipe.ingredientSections = trimmedIngredientSections
        recipe.stepSections = trimmedStepSections
        recipe.mealTypes = mealTypes.inDisplayOrder()
        recipe.photoID = photoID
        return recipe
    }
}

/// Groups each item under the section row above it. Items before the first section row go in
/// a section without a title. A section row left blank is dropped, so its items join the
/// section above. A named section with no items is kept, so nothing people typed is lost.
private func sections<Row, Item: Codable & Hashable & Sendable>(
    from rows: [Row],
    title: (Row) -> String?,
    item: (Row) -> Item?
) -> [RecipeSection<Item>] {
    var sections = [RecipeSection<Item>(title: nil, items: [])]
    for row in rows {
        if let title = title(row) {
            let title = trimmed(title)
            if !title.isEmpty {
                sections.append(RecipeSection(title: title, items: []))
            }
        } else if let item = item(row) {
            sections[sections.count - 1].items.append(item)
        }
    }
    if sections[0].items.isEmpty {
        sections.removeFirst()
    }
    return sections
}

private func rows<Item: Codable & Hashable & Sendable, Row>(
    from sections: [RecipeSection<Item>],
    section: (String) -> Row,
    item: (Item) -> Row
) -> [Row] {
    sections.flatMap { recipeSection in
        let heading = recipeSection.title.map { [section($0)] } ?? []
        return heading + recipeSection.items.map(item)
    }
}

extension String {
    /// Joins the lines with spaces. Returns whether there was a line break to remove.
    mutating func removeLineBreaks() -> Bool {
        guard contains(where: \.isNewline) else { return false }
        self = split(whereSeparator: \.isNewline).joined(separator: " ")
        return true
    }
}

private func trimmed(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}
