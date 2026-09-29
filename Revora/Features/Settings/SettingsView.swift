import SwiftUI

struct SettingsView: View {
    var body: some View {
        ContentUnavailableView("Settings", systemImage: "gearshape")
            .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
