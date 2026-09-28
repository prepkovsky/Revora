//
//  MainTabView.swift
//  Revora
//
//  Created by Patrik Repkovsky on 28/09/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("Recipes", systemImage: "book") {
                NavigationStack {
                    RecipesView()
                }
            }

            Tab("New Recipe", systemImage: "plus") {
                NavigationStack {
                    ContentUnavailableView("New Recipe", systemImage: "plus")
                        .navigationTitle("New Recipe")
                }
            }

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
