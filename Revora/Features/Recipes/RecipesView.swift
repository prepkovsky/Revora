//
//  RecipesView.swift
//  Revora
//
//  Created by Patrik Repkovsky on 28/09/2026.
//

import SwiftUI

struct RecipesView: View {
    @State private var isShowingEditor = false

    var body: some View {
        ContentUnavailableView("Recipes", systemImage: "book")
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Recipe", systemImage: "plus") {
                        isShowingEditor = true
                    }
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                RecipeEditorView()
            }
    }
}

#Preview {
    NavigationStack {
        RecipesView()
    }
}
