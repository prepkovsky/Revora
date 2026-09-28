//
//  RecipesView.swift
//  Revora
//
//  Created by Patrik Repkovsky on 28/09/2026.
//

import SwiftUI

struct RecipesView: View {
    var body: some View {
        ContentUnavailableView("Recipes", systemImage: "book")
            .navigationTitle("Recipes")
    }
}

#Preview {
    NavigationStack {
        RecipesView()
    }
}
