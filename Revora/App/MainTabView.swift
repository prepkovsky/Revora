import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("Recipes", systemImage: "book") {
                NavigationStack {
                    RecipesView()
                }
            }

            Tab("Account", systemImage: "person.crop.circle") {
                NavigationStack {
                    AccountView()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthService())
        .environment(RecipeRepository())
}
