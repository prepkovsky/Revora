import FirebaseFirestore
import Observation
import os

@Observable
final class RecipeRepository {
    private nonisolated static let logger = Logger(subsystem: "Revora", category: "Recipes")

    /// The signed-in user's recipes, most recently updated first.
    private(set) var recipes: [Recipe] = []

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
            }
        }

        let query = Self.recipesCollection(ownerID: ownerID).order(by: "updatedAt", descending: true)
        do {
            for try await snapshot in query.snapshots {
                recipes = snapshot.documents.compactMap(Self.decode)
            }
        } catch where !Task.isCancelled {
            // Signing out can fail the listener just before the task is cancelled.
            Self.logger.error("Recipe listener failed: \(error)")
        } catch {}
    }

    // Writes go to Firestore's local cache and sync in the background. Awaiting them
    // would wait for the server, which never answers while offline.

    /// The returned recipe has its ID already, generated on the device.
    func create(title: String, ingredients: [Ingredient], steps: [String]) throws(RecipeError) -> Recipe {
        let document = try recipesCollection().document()
        let now = Date.now
        let recipe = Recipe(
            id: document.documentID,
            title: title,
            ingredients: ingredients,
            steps: steps,
            createdAt: now,
            updatedAt: now
        )
        try write(recipe, to: document)
        return recipe
    }

    /// Saves edits and marks the recipe as updated now.
    func update(_ recipe: Recipe) throws(RecipeError) {
        var recipe = recipe
        recipe.updatedAt = .now
        try write(recipe, to: recipesCollection().document(recipe.id))
    }

    func delete(_ recipe: Recipe) throws(RecipeError) {
        try recipesCollection().document(recipe.id).delete(completion: Self.logFailure("Delete"))
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
