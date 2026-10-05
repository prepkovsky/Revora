import SwiftUI

/// Open-source code that ships inside the app. Their licences ask for their text to come
/// with the app, so these stay in the app even once the other legal pages move to a website.
/// Update the list when a package is added, or when Firebase starts linking another one.
nonisolated struct OpenSourceComponent: Identifiable, Sendable {
    let name: String
    let license: String
    /// A text file in the app bundle.
    let licenseFile: String
    var notice: String?

    var id: String { name }

    var licenseText: String? {
        LegalText.bundled(licenseFile, withExtension: "txt")
    }

    static let all: [OpenSourceComponent] = [
        OpenSourceComponent(name: "Abseil", license: "Apache License 2.0", licenseFile: "Apache-2.0"),
        OpenSourceComponent(
            name: "BoringSSL",
            license: "Apache License 2.0",
            licenseFile: "Apache-2.0",
            // Required by the OpenSSL and SSLeay licences that cover BoringSSL's older code.
            notice: """
                BoringSSL is a fork of OpenSSL. This product includes software developed by the \
                OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/). This \
                product includes cryptographic software written by Eric Young (eay@cryptsoft.com).
                """
        ),
        OpenSourceComponent(name: "Firebase Apple SDK", license: "Apache License 2.0", licenseFile: "Apache-2.0"),
        OpenSourceComponent(name: "Fraunces", license: "SIL Open Font License 1.1", licenseFile: "Fraunces-OFL"),
        OpenSourceComponent(name: "GoogleUtilities", license: "Apache License 2.0 and MIT License", licenseFile: "GoogleUtilities-LICENSE"),
        OpenSourceComponent(name: "GTM Session Fetcher", license: "Apache License 2.0", licenseFile: "Apache-2.0"),
        OpenSourceComponent(name: "gRPC", license: "Apache License 2.0", licenseFile: "Apache-2.0"),
        OpenSourceComponent(name: "Interop for Google SDKs", license: "Apache License 2.0", licenseFile: "Apache-2.0"),
        OpenSourceComponent(name: "LevelDB", license: "BSD 3-Clause License", licenseFile: "LevelDB-LICENSE"),
        OpenSourceComponent(name: "nanopb", license: "zlib License", licenseFile: "nanopb-LICENSE"),
    ]
}

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            Section {
                ForEach(OpenSourceComponent.all) { component in
                    NavigationLink {
                        LicenseView(component: component)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: component.name)
                            Text(verbatim: component.license)
                                .font(.subheadline)
                                .foregroundStyle(.secondaryText)
                        }
                    }
                }
            } footer: {
                Text("Revora is built with these open-source projects. Thank you to everyone who works on them.")
                    .foregroundStyle(.secondaryText)
            }
            .listRowBackground(Color.surface)
        }
        .scrollContentBackground(.hidden)
        .background(.appBackground)
        .navigationTitle("Acknowledgments")
    }
}

private struct LicenseView: View {
    let component: OpenSourceComponent

    private var blocks: [LegalText.Block]? {
        guard let text = component.licenseText else { return nil }
        let notice = component.notice.map { [LegalText.Block.paragraph($0)] } ?? []
        return notice + LegalText.blocks(from: text)
    }

    var body: some View {
        LegalDocumentView(blocks: blocks)
            .font(.footnote)
            .navigationTitle(component.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AcknowledgmentsView()
    }
}
