import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        Group {
            switch authService.state {
            case .loading:
                DelayedProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
