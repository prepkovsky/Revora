//
//  SettingsView.swift
//  Revora
//
//  Created by Patrik Repkovsky on 28/09/2026.
//

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
