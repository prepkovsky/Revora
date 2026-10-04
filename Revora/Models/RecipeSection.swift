import Foundation

/// A named part of a recipe's ingredients or steps, like "For the sauce" or "Make the dough".
nonisolated struct RecipeSection<Item: Codable & Hashable & Sendable>: Codable, Hashable, Sendable {
    /// `nil` for the items before the first named section, and for recipes without sections.
    var title: String?
    var items: [Item]

    /// The whole list as one section without a title, or no section when it's empty.
    static func untitled(_ items: [Item]) -> [Self] {
        items.isEmpty ? [] : [Self(title: nil, items: items)]
    }
}
