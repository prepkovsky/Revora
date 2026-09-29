import FirebaseCore
import SwiftUI

@main
struct RevoraApp: App {
    @State private var authService = AuthService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
        }
    }
}
