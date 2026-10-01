import FirebaseFirestore
import Foundation
import Testing
@testable import Revora

/// Uses Firestore's own encoder and decoder, which run offline, so the tests see what Firestore stores.
struct RecipeCodingTests {
    private let recipe = Recipe(
        id: "recipe-1",
        title: "Pancakes",
        ingredients: [
            Ingredient(name: "Flour", quantity: "200 g"),
            Ingredient(name: "Milk", quantity: "300 ml"),
        ],
        steps: ["Whisk everything together.", "Fry in a hot pan."],
        photoID: "photo-1",
        isFavorite: true,
        // Whole seconds, so the round trip through Timestamp compares exactly.
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        updatedAt: Date(timeIntervalSince1970: 1_790_000_600),
        lastOpenedAt: Date(timeIntervalSince1970: 1_790_001_200)
    )

    private func decode(_ data: [String: Any], id: String? = "recipe-1") throws -> Recipe {
        let decoder = Firestore.Decoder()
        decoder.userInfo[Recipe.documentIDKey] = id
        return try decoder.decode(Recipe.self, from: data)
    }

    @Test func encodesSchemaFields() throws {
        let data = try Firestore.Encoder().encode(recipe)

        #expect(Set(data.keys) == [
            "title", "ingredients", "steps", "photoID", "isFavorite", "createdAt", "updatedAt", "lastOpenedAt",
        ])
        #expect(data["photoID"] as? String == "photo-1")
        #expect(data["title"] as? String == "Pancakes")
        #expect(data["steps"] as? [String] == recipe.steps)
        #expect(data["isFavorite"] as? Bool == true)
        #expect(data["createdAt"] as? Timestamp == Timestamp(date: recipe.createdAt))

        let ingredients = try #require(data["ingredients"] as? [[String: Any]])
        #expect(ingredients.count == 2)
        #expect(ingredients.first?["name"] as? String == "Flour")
        #expect(ingredients.first?["quantity"] as? String == "200 g")
    }

    @Test func leavesOutMissingLastOpened() throws {
        var unopened = recipe
        unopened.lastOpenedAt = nil
        let data = try Firestore.Encoder().encode(unopened)
        #expect(data["lastOpenedAt"] == nil)
    }

    @Test func leavesOutMissingPhoto() throws {
        var withoutPhoto = recipe
        withoutPhoto.photoID = nil
        let data = try Firestore.Encoder().encode(withoutPhoto)
        #expect(data["photoID"] == nil)
    }

    @Test func decodesRecipeSavedBeforePhotos() throws {
        var data = try Firestore.Encoder().encode(recipe)
        data["photoID"] = nil
        #expect(try decode(data).photoID == nil)
    }

    @Test func roundTrips() throws {
        let data = try Firestore.Encoder().encode(recipe)
        #expect(try decode(data) == recipe)
    }

    @Test func takesIDFromDocument() throws {
        let data = try Firestore.Encoder().encode(recipe)
        #expect(try decode(data, id: "other-id").id == "other-id")
    }

    @Test func decodesRecipeNeverOpened() throws {
        var data = try Firestore.Encoder().encode(recipe)
        data["lastOpenedAt"] = nil
        #expect(try decode(data).lastOpenedAt == nil)
    }

    @Test func ignoresUnknownFields() throws {
        // A newer app version may add fields that this version doesn't know.
        var data = try Firestore.Encoder().encode(recipe)
        data["servings"] = 4
        #expect(try decode(data) == recipe)
    }

    @Test func requiresDocumentID() throws {
        let data = try Firestore.Encoder().encode(recipe)
        #expect(throws: DecodingError.self) { try decode(data, id: nil) }
    }

    @Test func requiresTitle() throws {
        var data = try Firestore.Encoder().encode(recipe)
        data["title"] = nil
        #expect(throws: DecodingError.self) { try decode(data) }
    }
}
