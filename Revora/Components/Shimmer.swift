import SwiftUI

extension View {
    /// A slow wave of light across a loading placeholder, in the reading direction.
    /// A slow, steady wave feels shorter than a pulse or a quick flash.
    func shimmering() -> some View {
        modifier(Shimmer())
    }
}

private struct Shimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let period = 1.8

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .mask {
                    // From the clock, so placeholders side by side show the same wave.
                    TimelineView(.animation) { context in
                        let progress = context.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: period) / period
                        // SwiftUI mirrors the gradient for right-to-left languages, so it runs their way too.
                        let center = -0.5 + 2 * progress
                        LinearGradient(
                            colors: [.black, .black.opacity(0.35), .black],
                            startPoint: UnitPoint(x: center - 0.5, y: 0.5),
                            endPoint: UnitPoint(x: center + 0.5, y: 0.5)
                        )
                    }
                }
        }
    }
}
