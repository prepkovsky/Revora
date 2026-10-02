import SwiftUI

extension View {
    /// Shows a failed recipe action, and clears the error when the alert closes.
    func recipeErrorAlert(_ title: LocalizedStringKey, error: Binding<RecipeError?>) -> some View {
        alert(
            title,
            isPresented: Binding { error.wrappedValue != nil } set: { if !$0 { error.wrappedValue = nil } },
            presenting: error.wrappedValue
        ) { _ in
            Button("OK") {}
        } message: { error in
            Text(error.message)
        }
    }
}
