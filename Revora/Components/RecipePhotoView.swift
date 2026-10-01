import SwiftUI

/// A recipe's cover photo, with a placeholder while it loads or when there isn't one.
/// It fills whatever frame it's given, so callers set the size and shape.
struct RecipePhotoView: View {
    let recipeID: Recipe.ID
    let photoID: String?
    let size: RecipePhotoStore.Size
    var placeholderFont: Font = .title2

    @Environment(RecipePhotoStore.self) private var photoStore

    @State private var loadedImage: UIImage?

    /// Anything already in memory shows straight away. For the full size that includes the
    /// thumbnail, which the list has usually loaded, so a header never starts out empty.
    private var image: UIImage? {
        guard let photoID else { return nil }
        return loadedImage
            ?? photoStore.cachedImage(photoID: photoID, size: size)
            ?? (size == .full ? photoStore.cachedImage(photoID: photoID, size: .thumbnail) : nil)
    }

    var body: some View {
        Color.appBackground
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else {
                    Image(systemName: "fork.knife")
                        .font(placeholderFont)
                        .foregroundStyle(.secondaryAccent)
                }
            }
            .clipped()
            .animation(.easeOut(duration: 0.2), value: loadedImage)
            // Decorative: the recipe's title right next to it carries the meaning.
            .accessibilityHidden(true)
            .task(id: photoID) {
                loadedImage = nil
                guard let photoID else { return }
                loadedImage = try? await photoStore.image(photoID: photoID, recipeID: recipeID, size: size)
            }
    }
}

extension RecipePhotoView {
    init(recipe: Recipe, size: RecipePhotoStore.Size, placeholderFont: Font = .title2) {
        self.init(recipeID: recipe.id, photoID: recipe.photoID, size: size, placeholderFont: placeholderFont)
    }
}
