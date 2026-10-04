import FirebaseFirestore
import Observation
import os

@Observable
final class RecipeRepository {
    private nonisolated static let logger = Logger(subsystem: "Revora", category: "Recipes")

    /// The signed-in user's recipes, most recently updated first.
    private(set) var recipes: [Recipe] = []

    /// Whether the first snapshot has arrived, so an empty list really means no recipes.
    private(set) var hasLoaded = false

    /// Whose recipes are loaded. Writes go under this user too.
    private var ownerID: String?

    /// Runs for as long as the calling task lives, so cancelling the task on
    /// sign-out stops the listener and clears the recipes.
    func observeRecipes(ownerID: String) async {
        self.ownerID = ownerID
        defer {
            // A cancelled listener can finish after the next user's has started.
            if self.ownerID == ownerID {
                self.ownerID = nil
                recipes = []
                hasLoaded = false
            }
        }

        let query = Self.recipesCollection(ownerID: ownerID).order(by: "updatedAt", descending: true)
        do {
            for try await snapshot in query.snapshots {
                recipes = snapshot.documents.compactMap(Self.decode)
                hasLoaded = true
            }
        } catch where !Task.isCancelled {
            // Signing out can fail the listener just before the task is cancelled.
            Self.logger.error("Recipe listener failed: \(error)")
        } catch {}
    }

    // Writes go to Firestore's local cache and sync in the background. Awaiting them
    // would wait for the server, which never answers while offline.

    /// Generated on the device, so a photo can be saved under the recipe before the recipe itself.
    func newRecipeID() throws(RecipeError) -> Recipe.ID {
        try recipesCollection().document().documentID
    }

    func create(
        id: Recipe.ID,
        title: String,
        ingredientSections: [RecipeSection<Ingredient>],
        stepSections: [RecipeSection<Step>],
        mealTypes: [MealType] = [],
        photoID: String? = nil
    ) throws(RecipeError) -> Recipe {
        let now = Date.now
        let recipe = Recipe(
            id: id,
            title: title,
            ingredientSections: ingredientSections,
            stepSections: stepSections,
            mealTypes: mealTypes,
            photoID: photoID,
            createdAt: now,
            updatedAt: now
        )
        try write(recipe, to: recipesCollection().document(id))
        return recipe
    }

    /// Saves edits and marks the recipe as updated now.
    func update(_ recipe: Recipe) throws(RecipeError) {
        var recipe = recipe
        recipe.updatedAt = .now
        try write(recipe, to: recipesCollection().document(recipe.id))
    }

    /// Only touches `lastOpenedAt`, so opening a recipe doesn't count as editing it.
    /// `updateData` fails for a deleted recipe instead of bringing it back.
    func markOpened(_ recipe: Recipe) throws(RecipeError) {
        try recipesCollection().document(recipe.id).updateData(
            [Recipe.CodingKeys.lastOpenedAt.stringValue: Timestamp(date: .now)],
            completion: Self.logFailure("Marking as opened")
        )
    }

    /// Only touches `isFavorite`, so a favorite doesn't count as an edit and move up in Recent.
    func setFavorite(_ isFavorite: Bool, for recipe: Recipe) throws(RecipeError) {
        try recipesCollection().document(recipe.id).updateData(
            [Recipe.CodingKeys.isFavorite.stringValue: isFavorite],
            completion: Self.logFailure("Favorite")
        )
    }

    /// The recipe goes first, then its photo, so a recipe never points at a missing photo.
    /// Firestore doesn't delete a document's subcollections with it, so the photo is deleted
    /// separately. If that fails, it's only logged: nothing points at the photo anymore.
    func delete(_ recipe: Recipe, photoStore: RecipePhotoStore) throws(RecipeError) {
        try recipesCollection().document(recipe.id).delete(completion: Self.logFailure("Delete"))
        guard let photoID = recipe.photoID else { return }
        do throws(PhotoError) {
            try photoStore.delete(photoID: photoID, recipeID: recipe.id)
        } catch {
            Self.logger.error("Deleting the photo of a deleted recipe failed: \(error)")
        }
    }

    /// Every recipe and photo, for deleting the account. Like `deleteAllPhotos`, it waits for
    /// the server. Reading from the server first also fails straight away when offline,
    /// before anything is deleted. Photos go first, so no recipe outlives its photo.
    func deleteAllRecipes(photoStore: RecipePhotoStore) async throws(RecipeError) {
        let collection = try recipesCollection()
        do {
            let documents = try await collection.getDocuments(source: .server).documents
            for document in documents {
                try await photoStore.deleteAllPhotos(recipeID: document.documentID)
            }
            // A batch holds at most 500 writes.
            for start in stride(from: 0, to: documents.count, by: 500) {
                let batch = Firestore.firestore().batch()
                for document in documents[start..<min(start + 500, documents.count)] {
                    batch.deleteDocument(document.reference)
                }
                try await batch.commit()
            }
        } catch {
            Self.logger.error("Deleting all recipes failed: \(error)")
            throw RecipeError(error)
        }
        photoStore.removeAllCachedImages()
    }

    private func write(_ recipe: Recipe, to document: DocumentReference) throws(RecipeError) {
        do {
            try document.setData(from: recipe, completion: Self.logFailure("Save"))
        } catch {
            Self.logger.error("Encoding recipe failed: \(error)")
            throw .unknown
        }
    }

    private func recipesCollection() throws(RecipeError) -> CollectionReference {
        guard let ownerID else { throw .signedOut }
        return Self.recipesCollection(ownerID: ownerID)
    }

    private static func recipesCollection(ownerID: String) -> CollectionReference {
        Firestore.firestore().collection("users").document(ownerID).collection("recipes")
    }

    /// Skips a document that doesn't decode, so one bad recipe doesn't hide the rest.
    private static func decode(_ snapshot: QueryDocumentSnapshot) -> Recipe? {
        let decoder = Firestore.Decoder()
        decoder.userInfo[Recipe.documentIDKey] = snapshot.documentID
        do {
            return try snapshot.data(as: Recipe.self, decoder: decoder)
        } catch {
            logger.error("Skipping recipe \(snapshot.documentID) that doesn't decode: \(error)")
            return nil
        }
    }

    /// The server can still reject a write after it's been saved locally.
    /// The listener then rolls the change back, so this only needs logging.
    private nonisolated static func logFailure(_ action: String) -> @Sendable (Error?) -> Void {
        { error in
            if let error {
                logger.error("\(action, privacy: .public) rejected by the server: \(error)")
            }
        }
    }
}
