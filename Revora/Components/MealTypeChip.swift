import SwiftUI

/// A meal type people can pick. A picked chip is filled and swaps its icon for a
/// checkmark, so the difference doesn't rely on color alone.
struct MealTypeChip: View {
    let mealType: MealType
    let isSelected: Bool
    /// Unpicked chips need to stand out from whatever they sit on.
    var background: Color = .surface
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // Not a Label: lists and forms space a label's icon out into a column.
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark" : mealType.systemImage)
                    .accessibilityHidden(true)
                Text(mealType.title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? AnyShapeStyle(.accentForeground) : AnyShapeStyle(.primary))
            .padding(.horizontal, 14)
            .frame(minHeight: 40)
            .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(background), in: .capsule)
            .contentShape(.capsule)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    FlowLayout {
        ForEach(MealType.allCases) { mealType in
            MealTypeChip(mealType: mealType, isSelected: mealType == .dinner) {}
        }
    }
    .padding()
    .background(.appBackground)
}
