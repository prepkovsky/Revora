import SwiftUI

/// Places views in rows like words in a paragraph, starting a new row when one is full,
/// so chips still fit at large text sizes.
struct FlowLayout: Layout {
    var spacing = 8.0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrange(subviews, width: bounds.width).frames
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(_ subviews: Subviews, width: Double) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var x = 0.0
        var y = 0.0
        var rowHeight = 0.0
        var usedWidth = 0.0

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)
            // Wider than a whole row: let it wrap its own text instead of overflowing.
            if size.width > width {
                size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            }
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }
        return (frames, CGSize(width: usedWidth, height: y + rowHeight))
    }
}
