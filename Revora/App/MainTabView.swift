import SwiftUI

struct MainTabView: View {
    @State private var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    HomeView()
                        .offlineIndicator()
                }
            }

            Tab("Recipes", systemImage: "fork.knife", value: .recipes) {
                NavigationStack {
                    RecipesView()
                        .offlineIndicator()
                }
            }

            Tab("Account", systemImage: "person.crop.circle", value: .account) {
                NavigationStack {
                    AccountView()
                        .offlineIndicator()
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
        .environment(Connectivity())
}
