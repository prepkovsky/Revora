import SwiftUI

struct RootView: View {
    // Temporary stand-in until AuthService provides the real auth state.
    @State private var isSignedIn = false

    var body: some View {
        Group {
            if isSignedIn {
                MainTabView()
            } else {
                AuthFlow()
            }
        }
        #if DEBUG
        .overlay(alignment: .bottom) {
            Button(isSignedIn ? "Debug: Sign Out" : "Debug: Sign In") {
                isSignedIn.toggle()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        #endif
    }
}

#Preview {
    RootView()
}
