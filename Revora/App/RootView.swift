import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(RecipeRepository.self) private var recipeRepository

    init() {
        // Not in the app's init: touching UIKit's appearance that early loses the app's accent color.
        DisplayFont.applyToNavigationBars()
    }

    var body: some View {
        Group {
            switch authService.state {
            case .loading:
                // Same logo in the same place as the launch screen, so launch flows straight into loading.
                ZStack {
                    Image(.launchLogo)
                        .accessibilityHidden(true)
                    DelayedProgressView()
                        .offset(y: 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .background(.appBackground)
            case .signedOut:
                AuthFlow()
            case .signedIn(let user):
                MainTabView()
                    .task(id: user.id) {
                        await recipeRepository.observeRecipes(ownerID: user.id)
                    }
            }
        }
        .task {
            await authService.observeAuthState()
        }
    }
}
