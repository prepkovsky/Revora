import SwiftUI

/// A spinner that only appears if the wait is long enough to notice,
/// so fast loads don't flash a loader.
struct DelayedProgressView: View {
    var delay: Duration = .milliseconds(400)

    @State private var isVisible = false

    var body: some View {
        ZStack {
            if isVisible {
                ProgressView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: delay)
            withAnimation { isVisible = true }
        }
    }
}

#Preview {
    DelayedProgressView()
}
