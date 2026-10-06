import FirebaseFunctions
import Foundation
import Observation
import os

/// A recipe read from a photo, in the shape the editor saves. It isn't saved yet and has no ID.
nonisolated struct ScannedRecipe: Hashable, Sendable {
    var title: String
    var ingredientSections: [RecipeSection<Ingredient>] = []
    var stepSections: [RecipeSection<Step>] = []
    var mealTypes: [MealType] = []
}

extension ScannedRecipe: Decodable {
    private enum CodingKeys: String, CodingKey {
        case title, ingredientSections, stepSections, mealTypes
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        ingredientSections = try container.decode([RecipeSection<Ingredient>].self, forKey: .ingredientSections)
        stepSections = try container.decode([RecipeSection<Step>].self, forKey: .stepSections)
        // Like saved recipes, skips meals a newer function may add.
        mealTypes = try container.decode([String].self, forKey: .mealTypes)
            .compactMap(MealType.init(rawValue:))
            .inDisplayOrder()
    }
}

/// Reads the recipe in a photo with the `scanRecipe` Cloud Function, so the editor can open
/// with it filled in. Nothing is saved here: people check the recipe and save it themselves.
@Observable
final class RecipeScanner {
    private nonisolated static let logger = Logger(subsystem: "Revora", category: "Scanning")

    /// A little longer than the function's own 90 seconds, instead of `withTimeout`'s 15.
    /// Reading a recipe usually takes several seconds.
    nonisolated static let timeout: TimeInterval = 100

    private nonisolated struct Request: Encodable, Sendable {
        /// A base64 JPEG.
        let image: String
    }

    private nonisolated struct Response: Decodable, Sendable {
        let recipe: ScannedRecipe
    }

    func scan(_ photo: Data) async throws(ScanError) -> ScannedRecipe {
        let image: String
        do {
            image = try await prepare(photo)
        } catch {
            throw ScanError(error)
        }

        var callable = Functions.functions().httpsCallable("scanRecipe", requestAs: Request.self, responseAs: Response.self)
        callable.timeoutInterval = Self.timeout
        do {
            let recipe = try await callable.call(Request(image: image)).recipe
            Self.logger.info("Scanned a recipe")
            return recipe
        } catch {
            Self.logger.error("Scanning failed: \(error)")
            throw ScanError(error)
        }
    }

    /// Shrinking and encoding a large photo takes a moment, so it runs off the main actor.
    @concurrent
    private nonisolated func prepare(_ photo: Data) async throws(PhotoError) -> String {
        try PhotoProcessor.prepareForScan(photo).base64EncodedString()
    }
}
