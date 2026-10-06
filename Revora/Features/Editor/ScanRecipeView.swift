import PhotosUI
import SwiftUI

/// Where a photo to scan comes from.
enum ScanPhotoSource: Identifiable {
    case camera
    case library

    var id: Self { self }
}

/// A photo picked for scanning. It's only loaded once the scan starts, because a photo
/// from iCloud can take a few seconds to arrive.
nonisolated struct ScanPhoto: Identifiable, Sendable {
    private enum Source: Sendable {
        case camera(UIImage)
        case library(PhotosPickerItem)
    }

    let id = UUID()
    private let source: Source

    init(_ image: UIImage) {
        source = .camera(image)
    }

    init(_ item: PhotosPickerItem) {
        source = .library(item)
    }

    @concurrent
    func load() async throws -> Data {
        let data: Data? = switch source {
        case .camera(let image): image.jpegData(compressionQuality: 0.9)
        case .library(let item): try await item.loadTransferable(type: Data.self)
        }
        guard let data else { throw ScanError.unreadableImage }
        return data
    }
}

extension View {
    /// Shows the camera or the photo library while `source` is set, and hands over what's picked.
    func scanPhotoPicker(_ source: Binding<ScanPhotoSource?>, onPick: @escaping (ScanPhoto) -> Void) -> some View {
        modifier(ScanPhotoPicker(source: source, onPick: onPick))
    }
}

private struct ScanPhotoPicker: ViewModifier {
    @Binding var source: ScanPhotoSource?
    let onPick: (ScanPhoto) -> Void

    @State private var libraryItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            // Runs out of process, so it needs no photo library permission.
            .photosPicker(
                isPresented: Binding { source == .library } set: { if !$0 { source = nil } },
                selection: $libraryItem,
                matching: .images
            )
            .onChange(of: libraryItem) {
                guard let item = libraryItem else { return }
                libraryItem = nil
                onPick(ScanPhoto(item))
            }
            .fullScreenCover(isPresented: Binding { source == .camera } set: { if !$0 { source = nil } }) {
                CameraPicker { onPick(ScanPhoto($0)) }
                    .ignoresSafeArea()
            }
    }
}

/// Reads the recipe in a photo, then opens the editor filled in with it. Nothing is saved
/// until people check the recipe and tap Save.
struct ScanRecipeView: View {
    private enum Phase: Equatable {
        case scanning
        case failed(ScanError)
        case scanned(ScannedRecipe)
        /// Typing the recipe in after all, when scanning isn't possible today.
        case manual
    }

    @Environment(RecipeScanner.self) private var scanner
    @Environment(Connectivity.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    @State private var photo: ScanPhoto
    @State private var phase = Phase.scanning
    /// Changes with every attempt, so Try Again scans the same photo again.
    @State private var attempt = UUID()
    @State private var preview: UIImage?
    @State private var isChoosingSource = false
    @State private var pickerSource: ScanPhotoSource?

    init(photo: ScanPhoto) {
        _photo = State(initialValue: photo)
    }

    var body: some View {
        switch phase {
        case .scanned(let recipe):
            RecipeEditorView(scanned: recipe)
        case .manual:
            RecipeEditorView()
        case .scanning, .failed:
            NavigationStack {
                Group {
                    if case .failed(let error) = phase {
                        failure(error)
                    } else {
                        ScanningView(preview: preview)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.appBackground)
                .navigationTitle("Scan Recipe")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        // Nothing is lost: a scan still running is just dropped.
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .task(id: attempt) { await scan() }
            .confirmationDialog("Scan Another Photo", isPresented: $isChoosingSource, titleVisibility: .hidden) {
                Button("Take Photo") { pickerSource = .camera }
                Button("Choose from Library") { pickerSource = .library }
            }
            .scanPhotoPicker($pickerSource) { photo in
                self.photo = photo
                preview = nil
                attempt = UUID()
            }
            .sensoryFeedback(trigger: phase) { _, phase in
                if case .failed = phase { .error } else { nil }
            }
        }
    }

    private func scan() async {
        phase = .scanning
        guard connectivity.isOnline else {
            phase = .failed(.offline)
            return
        }

        do {
            let data = try await photo.load()
            preview = await UIImage(data: data)?.byPreparingThumbnail(ofSize: CGSize(width: 800, height: 800))
            let recipe = try await scanner.scan(data)
            guard !Task.isCancelled else { return }
            withAnimation {
                phase = .scanned(recipe)
            }
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failed(error as? ScanError ?? .unreadableImage)
        }
    }

    private func failure(_ error: ScanError) -> some View {
        ContentUnavailableView {
            EmptyStateLabel(error.title, systemImage: error.systemImage)
        } description: {
            Text(error.message)
                .foregroundStyle(.secondaryText)
        } actions: {
            switch error {
            case .offline, .timedOut, .unavailable, .unknown:
                Button("Try Again") { attempt = UUID() }
                    .buttonStyle(.primary)
                Button("Choose Another Photo", action: chooseAnotherPhoto)
            case .unreadableImage, .noRecipeFound, .photoNotAllowed:
                Button("Try Another Photo", action: chooseAnotherPhoto)
                    .buttonStyle(.primary)
            case .dailyLimitReached:
                Button("Type It In Instead") {
                    withAnimation { phase = .manual }
                }
                .buttonStyle(.primary)
            case .signedOut, .emailNotConfirmed:
                Button("Done") { dismiss() }
                    .buttonStyle(.primary)
            }
        }
    }

    /// Without a camera there's only one choice, so it skips the dialog.
    private func chooseAnotherPhoto() {
        if CameraPicker.isAvailable {
            isChoosingSource = true
        } else {
            pickerSource = .library
        }
    }
}

/// The photo being read, with a spinner. Reading takes several seconds, longer for a long recipe.
private struct ScanningView: View {
    let preview: UIImage?

    @State private var isTakingLong = false

    var body: some View {
        VStack(spacing: 24) {
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    // Before the frame, so it rounds the photo rather than the space around it.
                    .clipShape(.rect(cornerRadius: 18))
                    .frame(maxWidth: 280, maxHeight: 280)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Reading the recipe…")
                    .font(.headline)
                Text(isTakingLong ? "Long recipes can take up to a minute." : "This takes a few seconds.")
                    .font(.subheadline)
                    .foregroundStyle(.secondaryText)
                    .contentTransition(.opacity)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
        }
        .padding()
        .animation(.easeOut(duration: 0.25), value: preview != nil)
        .animation(.easeOut(duration: 0.25), value: isTakingLong)
        .task {
            try? await Task.sleep(for: .seconds(10))
            isTakingLong = true
        }
    }
}

private extension ScanError {
    var title: LocalizedStringResource {
        switch self {
        case .offline: "You're Offline"
        case .dailyLimitReached: "Daily Limit Reached"
        case .noRecipeFound: "No Recipe Found"
        case .photoNotAllowed, .unreadableImage: "Can't Scan This Photo"
        default: "Couldn't Read Recipe"
        }
    }

    var systemImage: String {
        switch self {
        case .offline: "wifi.slash"
        case .timedOut, .dailyLimitReached: "clock"
        case .noRecipeFound: "text.magnifyingglass"
        case .photoNotAllowed, .unreadableImage: "photo"
        default: "exclamationmark.triangle"
        }
    }
}
