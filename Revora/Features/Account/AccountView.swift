import SwiftUI

struct AccountView: View {
    @Environment(AuthService.self) private var authService

    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system
    @State private var logOutError: AuthError?

    private var user: AuthUser? {
        authService.currentUser
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Revora \(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                AccountHeader(name: user?.name, email: user?.email)
            }
            .listRowBackground(Color.surface)

            Section {
                NavigationLink {
                    ChangeNameView(currentName: user?.name)
                } label: {
                    Label(user?.name == nil ? "Add Your Name" : "Change Name", systemImage: "person")
                }
                NavigationLink {
                    ChangeEmailView(currentEmail: user?.email)
                } label: {
                    Label("Change Email", systemImage: "envelope")
                }
                NavigationLink {
                    ChangePasswordView()
                } label: {
                    Label("Change Password", systemImage: "key")
                }
            }
            .listRowBackground(Color.surface)

            Section {
                Picker("Appearance", systemImage: "circle.lefthalf.filled", selection: $appearance) {
                    ForEach(Appearance.allCases) { appearance in
                        Text(appearance.title)
                    }
                }
            }
            .listRowBackground(Color.surface)

            Section("Legal") {
                ForEach(LegalPage.allCases) { page in
                    NavigationLink {
                        LegalPageView(page: page)
                    } label: {
                        Label { Text(page.title) } icon: { Image(systemName: page.systemImage) }
                    }
                }
                NavigationLink {
                    AcknowledgmentsView()
                } label: {
                    Label("Acknowledgments", systemImage: "heart.text.square")
                }
            }
            .listRowBackground(Color.surface)

            Section {
                // Logging out loses nothing, so it doesn't ask first.
                Button(action: logOut) {
                    Label {
                        // `.primary` inside a button means the button's tint, so it's set as a color.
                        Text("Log Out")
                            .foregroundStyle(Color.primary)
                    } icon: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                .listRowBackground(Color.surface)
                // The tinted row below already marks the edge, and an inset divider on it looks misaligned.
                .listRowSeparator(.hidden, edges: .bottom)

                // The next page explains what's deleted and asks for the password.
                NavigationLink {
                    DeleteAccountView()
                } label: {
                    Label("Delete Account", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .listRowBackground(Color.red.opacity(0.07))
                .listRowSeparator(.hidden, edges: .top)
            } header: {
                Text("Danger Zone")
            } footer: {
                Text(verbatim: version)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
        .scrollContentBackground(.hidden)
        .background(.appBackground)
        .navigationTitle("Account")
        // Shows changes made elsewhere, like an email confirmed on another device.
        .task {
            await authService.refreshUser()
        }
        .alert(
            "Couldn't Log Out",
            isPresented: Binding { logOutError != nil } set: { if !$0 { logOutError = nil } },
            presenting: logOutError
        ) { _ in
            Button("Try Again", action: logOut)
            Button("Cancel", role: .cancel) {}
        } message: { error in
            Text(error.message)
        }
    }

    private func logOut() {
        do throws(AuthError) {
            try authService.logOut()
        } catch {
            logOutError = error
        }
    }
}

private struct AccountHeader: View {
    let name: String?
    let email: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var avatarSize = 56.0

    private var initial: String {
        (name ?? email)?.first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        // Side by side, the email would wrap after a few letters at accessibility sizes.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 16))

        layout {
            Text(initial)
                .font(.display(.title))
                .foregroundStyle(.accentForeground)
                .frame(width: avatarSize, height: avatarSize)
                .background(.tint, in: .circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                if let name {
                    Text(name)
                        .font(.display(.title3))
                    Text(email ?? "No email address")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                } else {
                    Text("Signed in as")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(email ?? "No email address")
                        .font(.headline)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
    .environment(AuthService())
    .environment(RecipeRepository())
    .environment(RecipePhotoStore())
}
