import PhotosUI
import SwiftUI

/// The cover photo at the top of the editor. A picked photo is shrunk straight away,
/// so the preview is what gets saved.
struct EditorPhotoSection: View {
    @Binding var photo: RecipeDraft.Photo?
    @Binding var isPreparing: Bool

    @Environment(RecipePhotoStore.self) private var photoStore

    @State private var libraryItem: PhotosPickerItem?
    @State private var isShowingLibrary = false
    @State private var isShowingCamera = false
    @State private var isShowingOptions = false
    @State private var error: PhotoError?

    var body: some View {
        Section {
            Button(action: showOptions) {
                tile
            }
            .buttonStyle(.plain)
            .disabled(isPreparing)
            .listRowInsets(EdgeInsets())
            // A dialog rather than a menu: a menu grows out of its label, which hides the photo while it's open.
            .confirmationDialog("Cover Photo", isPresented: $isShowingOptions, titleVisibility: .hidden) {
                Button("Choose from Library") {
                    isShowingLibrary = true
                }
                if CameraPicker.isAvailable {
                    Button("Take Photo") {
                        isShowingCamera = true
                    }
                }
                if photo != nil {
                    Button("Remove Photo", role: .destructive) {
                        photo = nil
                    }
                }
            }
        }
        .listRowBackground(Color.surface)
        // Runs out of process, so it needs no photo library permission.
        .photosPicker(isPresented: $isShowingLibrary, selection: $libraryItem, matching: .images)
        .onChange(of: libraryItem) {
            guard let item = libraryItem else { return }
            libraryItem = nil
            Task {
                await usePhoto { try await item.loadTransferable(type: Data.self) }
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { image in
                Task {
                    await usePhoto { image.jpegData(compressionQuality: 0.9) }
                }
            }
            .ignoresSafeArea()
        }
        .alert(
            "Couldn't Use Photo",
            isPresented: Binding { error != nil } set: { if !$0 { error = nil } },
            presenting: error
        ) { _ in
            Button("OK") {}
        } message: { error in
            Text(error.message)
        }
    }

    /// Without a camera or a photo there's only one choice, so it skips the dialog.
    private func showOptions() {
        if photo == nil && !CameraPicker.isAvailable {
            isShowingLibrary = true
        } else {
            isShowingOptions = true
        }
    }

    private var tile: some View {
        Group {
            switch photo {
            case .picked(let picked):
                Color.clear
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay {
                        Image(uiImage: picked.preview)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            case .saved(let photoID, let recipeID):
                RecipePhotoView(recipeID: recipeID, photoID: photoID, size: .full, placeholderFont: .largeTitle)
                    .aspectRatio(4 / 3, contentMode: .fit)
            case nil:
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondaryAccent)
                    Text("Add Photo")
                        .font(.headline)
                        .foregroundStyle(.tint)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
        .overlay {
            if isPreparing {
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: .circle)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(photo == nil ? "Add Photo" : "Change Photo")
    }

    /// Covers both the hand-off from the picker, which can take a few seconds, and the resizing.
    private func usePhoto(_ load: () async throws -> Data?) async {
        isPreparing = true
        defer { isPreparing = false }
        do {
            guard let data = try await load() else { throw PhotoError.unreadableImage }
            let prepared = try await photoStore.prepare(data)
            guard let preview = UIImage(data: prepared.full) else { throw PhotoError.unreadableImage }
            photo = .picked(RecipeDraft.PickedPhoto(prepared: prepared, preview: preview))
        } catch let error as PhotoError {
            self.error = error
        } catch {
            self.error = .unreadableImage
        }
    }
}
