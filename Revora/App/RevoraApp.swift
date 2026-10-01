import FirebaseCore
import SwiftUI

@main
struct RevoraApp: App {
    @State private var authService = AuthService()
    @State private var recipeRepository = RecipeRepository()
    @State private var photoStore = RecipePhotoStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(recipeRepository)
                .environment(photoStore)
        }
    }
}
