#if DEBUG
import SwiftUI

/// Temporary, until the editor can add photos: saves a generated photo to the recipe
/// and loads both sizes back.
struct PhotoDebugSection: View {
    let recipe: Recipe

    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(RecipePhotoStore.self) private var photoStore

    @State private var status = ""
    @State private var images: [RecipePhotoStore.Size: UIImage] = [:]

    var body: some View {
        Section("Debug: Photo") {
            Button("Add Sample Photo") {
                Task { await addSamplePhoto() }
            }
            if !status.isEmpty {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach([RecipePhotoStore.Size.thumbnail, .full], id: \.self) { size in
                if let image = images[size] {
                    VStack(alignment: .leading) {
                        Text("\(size.rawValue): \(Int(image.size.width * image.scale)) × \(Int(image.size.height * image.scale)) px")
                            .font(.footnote)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                    }
                }
            }
        }
        .listRowBackground(Color.surface)
        .task(id: recipe.photoID) {
            await load()
        }
    }

    private func addSamplePhoto() async {
        do {
            let photo = try await photoStore.prepare(Self.sampleJPEG())
            let photoID = try photoStore.save(photo, recipeID: recipe.id)
            var updated = recipe
            updated.photoID = photoID
            try recipeRepository.update(updated)
            if let oldPhotoID = recipe.photoID {
                try photoStore.delete(photoID: oldPhotoID, recipeID: recipe.id)
            }
            status = "Saved \(photoID): \(photo.full.count / 1024) KB + \(photo.thumbnail.count / 1024) KB"
        } catch {
            status = "Failed: \(error)"
        }
    }

    private func load() async {
        images = [:]
        guard let photoID = recipe.photoID else { return }
        for size in [RecipePhotoStore.Size.thumbnail, .full] {
            do {
                images[size] = try await photoStore.image(photoID: photoID, recipeID: recipe.id, size: size)
            } catch {
                status = "Loading \(size.rawValue) failed: \(error)"
            }
        }
    }

    /// A 12 MP gradient, about the size of an iPhone photo.
    private static func sampleJPEG() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: 4032, height: 3024)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let colors = [UIColor.systemOrange.cgColor, UIColor.systemTeal.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            let text = Date.now.formatted(date: .omitted, time: .standard) as NSString
            text.draw(at: CGPoint(x: 200, y: 200), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 400), .foregroundColor: UIColor.white])
        }
        return image.jpegData(compressionQuality: 0.95)!
    }
}
#endif
