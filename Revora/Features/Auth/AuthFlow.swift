import SwiftUI

struct AuthFlow: View {
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}

#Preview {
    AuthFlow()
        .environment(AuthService())
}
