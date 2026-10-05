import SwiftUI

/// Takes the place of the recipes when they couldn't load, instead of a spinner that never
/// ends or an empty state that suggests they're gone.
struct RecipesLoadFailedView: View {
    let error: RecipeError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(displayTitle: "Couldn't Load Recipes", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.primary)
        }
    }
}

#Preview {
    RecipesLoadFailedView(error: .quotaExceeded) {}
}
