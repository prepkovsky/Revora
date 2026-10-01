import FirebaseAuth
import FirebaseFirestore
import Observation
import os
import UIKit

/// Saves, loads and deletes recipe cover photos. Recipes only keep the photo's ID,
/// so moving photos to Cloud Storage later would only change this type.
@Observable
final class RecipePhotoStore {
    enum Size: String {
        case full = "photos"
        case thumbnail = "thumbnails"
    }

    private nonisolated static let logger = Logger(subsystem: "Revora", category: "Photos")

    @ObservationIgnored private let images = NSCache<NSString, UIImage>()

    /// Resizing a large photo takes a moment, so it runs off the main actor.
    @concurrent
    nonisolated func prepare(_ data: Data) async throws(PhotoError) -> PreparedPhoto {
        try PhotoProcessor.prepare(data)
    }

    /// Like recipe writes, this goes to Firestore's local cache and syncs in the background,
    /// so it works offline. Both sizes are written together, so neither exists without the other.
    func save(_ photo: PreparedPhoto, recipeID: Recipe.ID) throws(PhotoError) -> String {
        let recipe = try recipeDocument(recipeID)
        let photoID = recipe.collection(Size.full.rawValue).document().documentID
        let batch = Firestore.firestore().batch()
        batch.setData(["data": photo.full], forDocument: Self.document(.full, photoID: photoID, in: recipe))
        batch.setData(["data": photo.thumbnail], forDocument: Self.document(.thumbnail, photoID: photoID, in: recipe))
        batch.commit(completion: Self.logFailure("Saving photo"))
        return photoID
    }

    func delete(photoID: String, recipeID: Recipe.ID) throws(PhotoError) {
        let recipe = try recipeDocument(recipeID)
        let batch = Firestore.firestore().batch()
        for size in [Size.full, .thumbnail] {
            batch.deleteDocument(Self.document(size, photoID: photoID, in: recipe))
            images.removeObject(forKey: Self.cacheKey(size, photoID: photoID))
        }
        batch.commit(completion: Self.logFailure("Deleting photo"))
    }

    /// A photo never changes once saved, so the device's cache is tried before the server.
    func image(photoID: String, recipeID: Recipe.ID, size: Size) async throws(PhotoError) -> UIImage {
        let key = Self.cacheKey(size, photoID: photoID)
        if let image = images.object(forKey: key) {
            return image
        }

        let document = Self.document(size, photoID: photoID, in: try recipeDocument(recipeID))
        let snapshot: DocumentSnapshot
        do {
            snapshot = try await document.getDocument(source: .cache)
        } catch {
            do {
                snapshot = try await document.getDocument()
            } catch {
                Self.logger.error("Loading photo \(photoID) failed: \(error)")
                throw PhotoError(error)
            }
        }

        guard snapshot.exists else { throw .notFound }
        guard let data = snapshot.data()?["data"] as? Data, let image = UIImage(data: data) else {
            throw .unreadableImage
        }
        Self.logger.info("Loaded \(size.rawValue, privacy: .public) \(photoID) from the \(snapshot.metadata.isFromCache ? "cache" : "server", privacy: .public)")

        // Decoding up front keeps scrolling smooth.
        let prepared = await image.byPreparingForDisplay() ?? image
        images.setObject(prepared, forKey: key)
        return prepared
    }

    /// The signed-in user, because the security rules only let people reach their own photos.
    private func recipeDocument(_ recipeID: Recipe.ID) throws(PhotoError) -> DocumentReference {
        guard let ownerID = Auth.auth().currentUser?.uid else { throw .signedOut }
        return Firestore.firestore()
            .collection("users").document(ownerID)
            .collection("recipes").document(recipeID)
    }

    private static func document(_ size: Size, photoID: String, in recipe: DocumentReference) -> DocumentReference {
        recipe.collection(size.rawValue).document(photoID)
    }

    private static func cacheKey(_ size: Size, photoID: String) -> NSString {
        "\(size.rawValue)/\(photoID)" as NSString
    }

    /// The server can still reject a write after it's been saved locally. Firestore then
    /// drops it from the cache, and a recipe whose photo is missing shows the placeholder.
    private nonisolated static func logFailure(_ action: String) -> @Sendable (Error?) -> Void {
        { error in
            if let error {
                logger.error("\(action, privacy: .public) rejected by the server: \(error)")
            }
        }
    }
}
