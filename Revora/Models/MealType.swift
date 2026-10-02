import Foundation

/// What a recipe is for. A fixed set rather than free-form tags, so it can
/// match the time of day and stay a single tap in the editor.
nonisolated enum MealType: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
    case dessert
    case drink

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        case .dessert: "Dessert"
        case .drink: "Drink"
        }
    }

    var systemImage: String {
        switch self {
        case .breakfast: "cup.and.saucer"
        case .lunch: "takeoutbag.and.cup.and.straw"
        case .dinner: "fork.knife"
        case .snack: "carrot"
        case .dessert: "birthday.cake"
        case .drink: "wineglass"
        }
    }
}

extension Sequence<MealType> {
    /// In the order they're listed everywhere, without repeats, so saved data stays tidy.
    func inDisplayOrder() -> [MealType] {
        let types = Set(self)
        return MealType.allCases.filter(types.contains)
    }
}
