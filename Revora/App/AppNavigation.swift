import Observation

enum AppTab: Hashable {
    case home
    case recipes
    case account
}

/// Which tab is showing and which recipes the Recipes tab lists, kept here
/// so one tab can send people to another, like Home's "See All" to Favorites.
@Observable
final class AppNavigation {
    var selectedTab = AppTab.home
    var recipeFilter = RecipeFilter.all

    func showRecipes(_ filter: RecipeFilter) {
        recipeFilter = filter
        selectedTab = .recipes
    }
}
