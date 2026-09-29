import SwiftUI

/// A primary button label that turns into a spinner while work is in progress.
/// The spinner waits a moment before appearing and then stays for a minimum
/// time, so quick requests don't flash it. The title keeps the label's size
/// so the button doesn't jump.
struct ProgressButtonLabel: View {
    let title: String
    let isInProgress: Bool
    var delay: Duration = .milliseconds(400)
    var minimumDuration: Duration = .milliseconds(500)

    @State private var spinnerShownAt: ContinuousClock.Instant?

    var body: some View {
        ZStack {
            Text(title)
                .opacity(spinnerShownAt == nil ? 1 : 0)

            if spinnerShownAt != nil {
                ProgressView()
                    .tint(.accentForeground)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(spinnerShownAt == nil ? "" : "In progress")
        .task(id: isInProgress) {
            if isInProgress {
                guard spinnerShownAt == nil else { return }
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                spinnerShownAt = .now
            } else if let spinnerShownAt {
                try? await Task.sleep(until: spinnerShownAt + minimumDuration)
                guard !Task.isCancelled else { return }
                self.spinnerShownAt = nil
            }
        }
    }
}

#Preview {
    Button {} label: {
        ProgressButtonLabel(title: "Create Account", isInProgress: true)
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(.primary)
    .padding()
}
