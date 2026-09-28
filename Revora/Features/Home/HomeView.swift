//
//  HomeView.swift
//  Revora
//
//  Created by Patrik Repkovsky on 28/09/2026.
//

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
