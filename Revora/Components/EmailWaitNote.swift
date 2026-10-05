import SwiftUI

/// Says when another link can be sent, counting down, in place of a button that would only fail.
struct EmailWaitNote: View {
    let wait: EmailRateLimit.Wait

    var body: some View {
        Label {
            message
        } icon: {
            Image(systemName: "clock")
        }
        .font(.footnote)
        .monospacedDigit()
        .foregroundStyle(.secondaryText)
    }

    private var message: Text {
        let countdown = Text(timerInterval: Date.now...wait.until, countsDown: true)
        return switch wait.reason {
        case .recentlySent:
            Text("You can ask for another link in \(countdown).")
        case .hourlyLimit:
            Text("You've asked for several links in the last hour. You can ask for another in \(countdown).")
        }
    }
}

extension View {
    /// Keeps `wait` current for emails of this kind to this address: checked again whenever
    /// the address or `trigger` changes, and cleared once it's over.
    func emailWait(
        _ wait: Binding<EmailRateLimit.Wait?>,
        before kind: EmailRateLimit.Kind,
        to address: String,
        trigger: Int = 0
    ) -> some View {
        modifier(EmailWaitModifier(wait: wait, kind: kind, address: address, trigger: trigger))
    }
}

private struct EmailWaitModifier: ViewModifier {
    @Binding var wait: EmailRateLimit.Wait?
    let kind: EmailRateLimit.Kind
    let address: String
    let trigger: Int

    @Environment(AuthService.self) private var authService

    private struct Key: Equatable {
        let address: String
        let trigger: Int
    }

    func body(content: Content) -> some View {
        content
            .task(id: Key(address: address, trigger: trigger)) {
                wait = authService.emailWait(before: kind, to: address)
                while let current = wait {
                    try? await Task.sleep(for: .seconds(max(current.until.timeIntervalSinceNow, 0)))
                    guard !Task.isCancelled else { return }
                    wait = authService.emailWait(before: kind, to: address)
                }
            }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        EmailWaitNote(wait: .init(reason: .recentlySent, until: .now + 42))
        EmailWaitNote(wait: .init(reason: .hourlyLimit, until: .now + 40 * 60))
    }
    .padding()
}
