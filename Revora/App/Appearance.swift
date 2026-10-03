import SwiftUI

/// Light or dark, chosen in Account. It's saved on the device rather than in the account,
/// because it's about this screen, not about the person's recipes.
nonisolated enum Appearance: String, CaseIterable, Identifiable, Sendable {
    // The raw values are saved, so renaming them resets everyone to System.
    case system
    case light
    case dark

    static let storageKey = "appearance"

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` follows the device.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
