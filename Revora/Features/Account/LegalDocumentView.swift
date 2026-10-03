import SwiftUI

/// Long legal text in a readable column. `nil` means the text couldn't be loaded.
struct LegalDocumentView: View {
    let blocks: [LegalText.Block]?
    /// Licences are plain text, where a `*` or `_` is meant literally.
    var parsesMarkdown = false

    var body: some View {
        if let blocks {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        view(for: block)
                    }
                }
                .textSelection(.enabled)
                .frame(maxWidth: 700, alignment: .leading)
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(.appBackground)
        } else {
            ContentUnavailableView {
                Label(displayTitle: "Couldn't Load This Page", systemImage: "doc.questionmark")
            }
            .background(.appBackground)
        }
    }

    @ViewBuilder
    private func view(for block: LegalText.Block) -> some View {
        switch block {
        case .heading(let text):
            Text(styled(text))
                .font(.display(.title3))
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            Text(styled(text))
        case .listItem(let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: "•")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(styled(text))
            }
        }
    }

    private func styled(_ text: String) -> AttributedString {
        guard parsesMarkdown,
              let styled = try? AttributedString(
                  markdown: text,
                  options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
              )
        else { return AttributedString(text) }
        return styled
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(
            blocks: LegalText.blocks(from: """
                *Last updated: October 3, 2026*

                ## What Revora stores

                - **Your recipes:** titles, ingredients and steps.
                - **Cover photos** you add to recipes.
                """),
            parsesMarkdown: true
        )
        .navigationTitle("Privacy Policy")
    }
}
