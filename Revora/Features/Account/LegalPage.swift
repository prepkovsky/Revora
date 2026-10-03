import SwiftUI

/// Revora's own legal pages, bundled with the app for now. Before an App Store release they
/// should move to a website and these rows should open its URLs instead: App Store Connect
/// asks for a privacy policy URL, and a website can be updated without shipping the app.
nonisolated enum LegalPage: String, CaseIterable, Identifiable, Sendable {
    // The raw values are the file names in Resources/Legal.
    case privacyPolicy = "PrivacyPolicy"
    case termsOfUse = "TermsOfUse"

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .privacyPolicy: "Privacy Policy"
        case .termsOfUse: "Terms of Use"
        }
    }

    var systemImage: String {
        switch self {
        case .privacyPolicy: "hand.raised"
        case .termsOfUse: "doc.text"
        }
    }

    var text: String? {
        LegalText.bundled(rawValue, withExtension: "md")
    }
}

struct LegalPageView: View {
    let page: LegalPage

    var body: some View {
        LegalDocumentView(blocks: page.text.map(LegalText.blocks), parsesMarkdown: true)
            .navigationTitle(Text(page.title))
    }
}

#Preview {
    NavigationStack {
        LegalPageView(page: .privacyPolicy)
    }
}
