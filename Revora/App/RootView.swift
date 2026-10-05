import SwiftUI

struct RootView: View {
    /// A new listener starts for each user, and when loading their recipes is tried again.
    private struct RecipeListener: Equatable {
        let ownerID: String
        let attempt: Int
    }

    @Environment(AuthService.self) private var authService
    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(Connectivity.self) private var connectivity

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system

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
            case .unverified(let user):
                NavigationStack {
                    VerifyEmailView(email: user.email)
                }
            case .signedIn(let user):
                MainTabView()
                    .task(id: RecipeListener(ownerID: user.id, attempt: recipeRepository.loadAttempt)) {
                        await recipeRepository.observeRecipes(ownerID: user.id)
                    }
            }
        }
        // Set once here so every screen follows it, including sheets and the auth flow.
        .preferredColorScheme(appearance.colorScheme)
        .task {
            await authService.observeAuthState()
        }
        .task {
            await connectivity.observe()
        }
        // Coming back from the mail app after confirming an email should take effect straight away,
        // not whenever Firebase next refreshes its token, up to an hour later.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, authService.state.hasSession else { return }
            Task { await authService.refreshUser() }
        }
        // The link may be opened on another device, so the app never goes away and comes back.
        .task(id: authService.pendingEmail) {
            for _ in 0..<60 {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, authService.pendingEmail != nil else { return }
                await authService.refreshUser()
            }
        }
    }
}
