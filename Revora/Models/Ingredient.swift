import Foundation

nonisolated struct Ingredient: Codable, Hashable, Sendable {
    var name: String
    /// Free text, e.g. "200 g" or "2 tbsp".
    var quantity: String
}
