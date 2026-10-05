import SwiftUI

/// The big card for the recipe people opened last.
struct ContinueCookingCard: View {
    let recipe: Recipe
    /// Passed in, so "Opened 5 minutes ago" keeps up while Home stays open.
    var now = Date.now

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var arrowSize = 40.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipePhotoView(recipe: recipe, size: .full, placeholderFont: .largeTitle)
                .aspectRatio(16 / 10, contentMode: .fit)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.display(.title2))
                        .foregroundStyle(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    if let openedAt = recipe.lastOpenedAt {
                        Group {
                            // Otherwise it reads "Opened now", straight after coming back from the recipe.
                            if now.timeIntervalSince(openedAt) < 60 {
                                Text("Opened just now")
                            } else {
                                Text("Opened \(openedAt, format: .relative(presentation: .named, unitsStyle: .wide))")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondaryText)
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Only a hint that the card opens. At accessibility text sizes the text needs its room.
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundStyle(.accentForeground)
                        .frame(width: arrowSize, height: arrowSize)
                        .background(.tint, in: .circle)
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(.rect(cornerRadius: 24))
        // Behind the clipped content, so the clip doesn't cut the shadow off.
        .background(.surface.cardShadow(), in: .rect(cornerRadius: 24))
        .contentShape(.rect(cornerRadius: 24))
    }
}

/// A recipe in one of Home's horizontal rows.
struct RecipeCard: View {
    let recipe: Recipe

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var scaledWidth = 150.0

    /// Grows with the text, but not so far that the next card stops peeking in.
    private var width: Double {
        min(scaledWidth, 260)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RecipePhotoView(recipe: recipe, size: .thumbnail)
                .frame(width: width, height: width)
                .clipShape(.rect(cornerRadius: 18))
                .background(.surface.cardShadow(), in: .rect(cornerRadius: 18))

            Text(recipe.title)
                .font(.display(.headline))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                // Titles line up at regular sizes. At accessibility sizes two lines hold too little.
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 5 : 2, reservesSpace: !dynamicTypeSize.isAccessibilitySize)
        }
        .frame(width: width, alignment: .leading)
        .contentShape(.rect)
    }
}

/// A shortcut under the greeting. Two sit side by side; one on its own lies flat,
/// so it doesn't leave a big empty block.
struct HomeActionTile: View {
    /// Side by side, each tile is too narrow for accessibility text sizes.
    static func rowLayout(for dynamicTypeSize: DynamicTypeSize) -> AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let systemImage: String
    var isProminent = false
    var isWide = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize = 44.0

    var body: some View {
        // At accessibility text sizes the text needs the whole width.
        let layout = isWide && !dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(HStackLayout(alignment: .center, spacing: 14))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
        layout {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isProminent ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondaryAccent))
                .frame(width: iconSize, height: iconSize)
                .background(isProminent ? AnyShapeStyle(.accentForeground) : AnyShapeStyle(.appBackground), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.display(.headline))
                Text(subtitle)
                    .font(.subheadline)
                    .opacity(isProminent ? 0.85 : 1)
                    .foregroundStyle(isProminent ? AnyShapeStyle(.accentForeground) : AnyShapeStyle(.secondaryText))
            }
            .multilineTextAlignment(.leading)
        }
        .foregroundStyle(isProminent ? AnyShapeStyle(.accentForeground) : AnyShapeStyle(.primary))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isWide ? .leading : .topLeading)
        .padding(16)
        .background((isProminent ? AnyShapeStyle(.tint) : AnyShapeStyle(.surface)).cardShadow(), in: .rect(cornerRadius: 22))
        .contentShape(.rect(cornerRadius: 22))
    }
}

/// A meal in Home's Browse by Meal grid, with how many recipes are marked for it.
struct MealTile: View {
    let mealType: MealType
    let count: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var iconSize = 40.0

    var body: some View {
        // At accessibility text sizes the name needs the whole width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Image(systemName: mealType.systemImage)
                .font(.headline)
                .foregroundStyle(.secondaryAccent)
                .frame(width: iconSize, height: iconSize)
                .background(.appBackground, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(mealType.title)
                    .font(.display(.headline))
                    .foregroundStyle(.primary)
                Group {
                    if count == 0 {
                        Text("None yet")
                    } else {
                        Text("^[\(count) recipe](inflect: true)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
            }
            .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.surface.cardShadow(), in: .rect(cornerRadius: 18))
        .contentShape(.rect(cornerRadius: 18))
    }
}

/// Cards press in a little, like the system's own, instead of just dimming.
struct CardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle { CardButtonStyle() }
}

extension ShapeStyle {
    /// A soft shadow for a card's background. White cards on the cream background have
    /// barely any edge without it. It's clear in dark mode, where cards are lighter instead.
    /// On the background rather than the card, so the text doesn't get a shadow too.
    func cardShadow() -> some ShapeStyle {
        shadow(.drop(color: .cardShadow, radius: 8, y: 2))
    }
}

#Preview {
    let recipe = Recipe(id: "1", title: "Banana Bread", createdAt: .now, updatedAt: .now, lastOpenedAt: .now.addingTimeInterval(-7200))
    ScrollView {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                HomeActionTile(title: "New Recipe", subtitle: "Add it to your cookbook", systemImage: "plus", isProminent: true)
                HomeActionTile(title: "Surprise Me", subtitle: "Pick one of your 12", systemImage: "dice")
            }
            .fixedSize(horizontal: false, vertical: true)
            ContinueCookingCard(recipe: recipe)
            RecipeCard(recipe: recipe)
        }
        .padding()
    }
    .background(.appBackground)
    .environment(RecipePhotoStore())
    .environment(Connectivity())
}
