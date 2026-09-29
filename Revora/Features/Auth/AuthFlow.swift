import SwiftUI

struct AuthFlow: View {
    var body: some View {
        NavigationStack {
            RegisterView()
        }
    }
}

#Preview {
    AuthFlow()
        .environment(AuthService())
}
