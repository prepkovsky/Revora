import SwiftUI

struct HomeView: View {
    var body: some View {
        ContentUnavailableView("Home", systemImage: "house")
            .background(.appBackground)
            .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
