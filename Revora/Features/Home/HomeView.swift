import SwiftUI

struct HomeView: View {
    @State private var isShowingEditor = false

    var body: some View {
        // Rechecks the hour every minute, so the greeting changes while Home stays open.
        TimelineView(.everyMinute) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What would you like to cook today?")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Button {
                        isShowingEditor = true
                    } label: {
                        Label("Create Recipe", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                }
                .padding()
            }
            .background(.appBackground)
            .navigationTitle(Text(Greeting(date: context.date).title))
        }
        .sheet(isPresented: $isShowingEditor) {
            RecipeEditorView()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(RecipeRepository())
    .environment(RecipePhotoStore())
}
