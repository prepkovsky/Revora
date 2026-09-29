import SwiftUI

struct AuthFlow: View {
    var body: some View {
        ContentUnavailableView("Log In", systemImage: "person.crop.circle")
    }
}

#Preview {
    AuthFlow()
}
