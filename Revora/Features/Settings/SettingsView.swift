import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService

    @State private var logOutError: AuthError?

    var body: some View {
        ContentUnavailableView {
            Label("Settings", systemImage: "gearshape")
        } actions: {
            Button("Log Out", role: .destructive, action: logOut)
        }
        .background(.appBackground)
        .navigationTitle("Settings")
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

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthService())
}
