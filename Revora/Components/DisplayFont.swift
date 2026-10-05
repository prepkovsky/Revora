import SwiftUI
import UIKit

/// Fraunces Soft, Revora's face for titles and headings. Body text, ingredients, steps
/// and fields stay in SF Pro, which reads better at small sizes.
///
/// The files are Fraunces with its soft serifs and weight baked in. They keep the optical
/// size axis, which iOS sets to match the point size, so big titles get finer details.
enum DisplayFont {
    static let semibold = "FrauncesSoft-SemiBold"
    static let italic = "FrauncesSoft-Italic"

    /// SwiftUI's font modifiers don't reach navigation bar titles, so they're set here, once.
    static func applyToNavigationBars() {
        let bar = UINavigationBar.appearance()
        if let font = UIFont(name: semibold, size: 34) {
            bar.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)]
        }
        if let font = UIFont(name: semibold, size: 17) {
            bar.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)]
        }
    }
}

extension Font {
    /// The display face at a text style's size, scaling with Dynamic Type like that style.
    static func display(_ style: Font.TextStyle, italic: Bool = false) -> Font {
        display(size: style.defaultSize, relativeTo: style, italic: italic)
    }

    /// The display face at a custom size, for the odd title that's bigger than any text style.
    static func display(size: CGFloat, relativeTo style: Font.TextStyle, italic: Bool = false) -> Font {
        .custom(italic ? DisplayFont.italic : DisplayFont.semibold, size: size, relativeTo: style)
    }
}

private extension Font.TextStyle {
    /// Sizes at the default text size (Large), which Dynamic Type scales from.
    var defaultSize: CGFloat {
        switch self {
        case .extraLargeTitle2: 28
        case .extraLargeTitle: 36
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        Text("Good evening").font(.display(.largeTitle))
        Text("What's for dinner?").font(.display(.title2, italic: true)).foregroundStyle(.secondaryText)
        Text("Crème Brûlée").font(.display(.headline))
    }
}
