import SwiftUI

struct MainTabView: View {
    @State private var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("Recipes", systemImage: "book", value: .recipes) {
                NavigationStack {
                    RecipesView()
                }
            }

            Tab("Account", systemImage: "person.crop.circle", value: .account) {
                NavigationStack {
                    AccountView()
                }
            }
        }
        .environment(navigation)
    }
}

#Preview {
    MainTabView()
        .environment(AuthService())
        .environment(RecipeRepository())
        .environment(RecipePhotoStore())
}
