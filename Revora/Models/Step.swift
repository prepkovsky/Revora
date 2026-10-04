import Foundation

nonisolated struct Step: Codable, Hashable, Sendable {
    var text: String
    /// Listed under the text, like the ingredients the step adds. Usually empty.
    var bullets: [String] = []
}
