import FirebaseCore
import SwiftUI

@main
struct RevoraApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
