import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService

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
            case .signedIn:
                MainTabView()
            }
        }
        .task {
            await authService.observeAuthState()
        }
    }
}
