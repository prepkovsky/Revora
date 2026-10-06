import FirebaseCore
import SwiftUI

@main
struct RevoraApp: App {
    @State private var authService = AuthService()
    @State private var recipeRepository = RecipeRepository()
    @State private var photoStore = RecipePhotoStore()
    @State private var recipeScanner = RecipeScanner()
    @State private var connectivity = Connectivity()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(recipeRepository)
                .environment(photoStore)
                .environment(recipeScanner)
                .environment(connectivity)
        }
    }
}
