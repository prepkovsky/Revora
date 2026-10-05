import Testing
@testable import Revora

struct AppNavigationTests {
    @Test func showingRecipesSwitchesToTheRecipesTab() {
        let navigation = AppNavigation()
        navigation.showRecipes(.favorites)
        #expect(navigation.selectedTab == .recipes)
        #expect(navigation.recipeFilter == .favorites)
    }

    @Test func showingRecipesForAMealSetsBothFilters() {
        let navigation = AppNavigation()
        navigation.showRecipes(.all, mealType: .dinner)
        #expect(navigation.recipeFilter == .all)
        #expect(navigation.mealType == .dinner)
    }

    /// Otherwise See All on Favorites could open still narrowed to an earlier meal.
    @Test func showingRecipesWithoutAMealClearsTheEarlierOne() {
        let navigation = AppNavigation()
        navigation.showRecipes(.all, mealType: .dinner)
        navigation.showRecipes(.favorites)
        #expect(navigation.mealType == nil)
    }
}
