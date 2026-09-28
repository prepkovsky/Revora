//
//  RecipeEditorView.swift
//  Revora
//
//  Created by Patrik Repkovsky on 28/09/2026.
//

import SwiftUI

struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView("New Recipe", systemImage: "square.and.pencil")
                .navigationTitle("New Recipe")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    RecipeEditorView()
}
