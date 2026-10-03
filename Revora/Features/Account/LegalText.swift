import Foundation

/// Splits legal text into blocks that wrap to the screen. Licence files are hard-wrapped
/// at about 80 columns, which reads badly on a phone, so their lines are joined back into
/// paragraphs. The app's own pages use the same format, plus `## ` for headings and `- `
/// for list items, with inline Markdown like `**bold**` inside a block.
nonisolated enum LegalText {
    enum Block: Equatable, Sendable {
        case heading(String)
        case paragraph(String)
        case listItem(String)
    }

    static func blocks(from text: String) -> [Block] {
        var blocks: [Block] = []
        var lines: [String] = []
        var isListItem = false

        func finishBlock() {
            guard !lines.isEmpty else { return }
            let text = lines.joined(separator: " ")
            blocks.append(isListItem ? .listItem(text) : .paragraph(text))
            lines = []
            isListItem = false
        }

        // `isNewline` also matches "\r\n", which is a single Character.
        for rawLine in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || isSeparator(line) {
                finishBlock()
            } else if line.hasPrefix("## ") {
                finishBlock()
                blocks.append(.heading(String(line.dropFirst(3))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                finishBlock()
                lines = [String(line.dropFirst(2))]
                isListItem = true
            } else if lines.isEmpty && isCapitalizedTitle(line) {
                // Licences title their sections like "PREAMBLE", straight above the text.
                blocks.append(.paragraph(line))
            } else {
                lines.append(line)
            }
        }
        finishBlock()
        return blocks
    }

    /// A text file from the app bundle, or `nil` if it's missing.
    static func bundled(_ name: String, withExtension fileExtension: String) -> String? {
        Bundle.main.url(forResource: name, withExtension: fileExtension)
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    /// A rule like "-----", which licences use between parts.
    private static func isSeparator(_ line: String) -> Bool {
        line.count >= 3 && line.allSatisfy { "-=_".contains($0) }
    }

    private static func isCapitalizedTitle(_ line: String) -> Bool {
        line.count <= 40 && line.contains(where: \.isLetter) && !line.contains(where: \.isLowercase)
    }
}
