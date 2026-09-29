import SwiftUI

struct HomeView: View {
    var body: some View {
        ContentUnavailableView("Home", systemImage: "house")
            .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
