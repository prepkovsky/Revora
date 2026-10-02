import Foundation

/// A recipe stored at `users/{uid}/recipes/{id}`.
nonisolated struct Recipe: Identifiable, Hashable, Sendable {
    /// The Firestore document ID. It isn't stored as a field.
    let id: String
    var title: String
    var ingredients: [Ingredient]
    /// In order.
    var steps: [String]
    /// In `MealType`'s order. Empty when none are picked.
    var mealTypes: [MealType] = []
    /// The cover photo, stored under the recipe in `photos` and `thumbnails`. `nil` when there's none.
    var photoID: String?
    var isFavorite = false
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
}

extension Recipe: Codable {
    /// Decoding reads the document ID from here, so a decoded recipe always has its real ID.
    /// Firestore's `@DocumentID` would do this too, but it makes `id` optional and ignores
    /// IDs set before saving, and recipe IDs are generated on the device.
    static let documentIDKey = CodingUserInfoKey(rawValue: "Recipe.documentID")!

    /// Also the Firestore field names, for updating a single field.
    enum CodingKeys: String, CodingKey {
        case title, ingredients, steps, mealTypes, photoID, isFavorite, createdAt, updatedAt, lastOpenedAt
    }

    init(from decoder: any Decoder) throws {
        guard let id = decoder.userInfo[Self.documentIDKey] as? String else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Recipe decoding needs the document ID in userInfo[Recipe.documentIDKey]."
            ))
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = id
        title = try container.decode(String.self, forKey: .title)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        steps = try container.decode([String].self, forKey: .steps)
        // Missing on recipes saved before meal types. Skips values a newer app version may add.
        mealTypes = try container.decodeIfPresent([String].self, forKey: .mealTypes)?
            .compactMap(MealType.init(rawValue:))
            .inDisplayOrder() ?? []
        photoID = try container.decodeIfPresent(String.self, forKey: .photoID)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        lastOpenedAt = try container.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
    }
}
