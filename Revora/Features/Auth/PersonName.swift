import Foundation

/// The optional name on an account. Anything goes, since names come in every shape;
/// the cap only keeps it to something that fits on screen.
enum PersonName {
    static let maximumLength = 50

    static var tooLong: String {
        "Use \(maximumLength) characters or fewer."
    }

    /// What a trimmed name still needs, or `nil` when it's fine. Empty means no name.
    static func issue(for name: String) -> String? {
        name.count > maximumLength ? tooLong : nil
    }

    static func trimmed(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
