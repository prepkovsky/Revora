import SwiftUI

struct HomeView: View {
    @Environment(AuthService.self) private var authService
    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isShowingEditor = false
    @State private var surpriseRecipe: Recipe?
    /// Like a spinner, the skeleton waits a moment, so a quick load doesn't flash it.
    @State private var isSkeletonVisible = false

    /// Where the greeting ends, measured from the bottom of the navigation bar.
    @State private var greetingBottom = Double.infinity

    private let margin = 16.0

    /// Like the recipe detail: the big greeting is part of the page, and a small
    /// one fades into the bar once the big one has gone under it.
    private var isGreetingInToolbar: Bool {
        greetingBottom < 0
    }

    var body: some View {
        // Rechecks the hour every minute, so the greeting changes while Home stays open.
        TimelineView(.everyMinute) { context in
            let greeting = Greeting(date: context.date)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header(greeting, date: context.date)
                    content(now: context.date)
                }
                .animation(.easeOut(duration: 0.25), value: isSkeletonVisible)
                .animation(.easeOut(duration: 0.25), value: recipeRepository.hasLoaded)
                .padding(.horizontal, margin)
                .padding(.bottom, 24)
                // Cards stretched across a whole iPad would be enormous.
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(.appBackground)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(greeting.title(firstName: authService.currentUser?.firstName))
                        .font(.display(.headline))
                        .opacity(isGreetingInToolbar ? 1 : 0)
                        .animation(.easeOut(duration: 0.15), value: isGreetingInToolbar)
                        .accessibilityHidden(!isGreetingInToolbar)
                }
            }
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipeID: recipe.id)
        }
        .navigationDestination(item: $surpriseRecipe) { recipe in
            RecipeDetailView(recipeID: recipe.id)
        }
        .sheet(isPresented: $isShowingEditor) {
            RecipeEditorView()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            isSkeletonVisible = true
        }
    }

    private func header(_ greeting: Greeting, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text(greeting.title(firstName: authService.currentUser?.firstName))
                .font(.display(size: 40, relativeTo: .largeTitle))
                .accessibilityAddTraits(.isHeader)
                .onGeometryChange(for: Double.self) { $0.frame(in: .scrollView).maxY } action: { greetingBottom = $0 }

            Text(greeting.prompt)
                .font(.display(.title2, italic: true))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    @ViewBuilder private func content(now: Date) -> some View {
        if let loadError = recipeRepository.loadError {
            RecipesLoadFailedView(error: loadError, retry: recipeRepository.retryLoading)
                .padding(.top, 40)
        } else if !recipeRepository.hasLoaded {
            if isSkeletonVisible {
                HomeSkeleton()
            }
        } else if recipeRepository.recipes.isEmpty {
            welcome
        } else {
            let summary = HomeSummary(recipes: recipeRepository.recipes, now: now)
            let greeting = Greeting(date: now)
            actions(summary, mealType: greeting.mealType)
            if let recipe = summary.continueRecipe {
                section("Continue Cooking") {
                    NavigationLink(value: recipe) {
                        ContinueCookingCard(recipe: recipe, now: now)
                    }
                    .buttonStyle(.card)
                }
            }
            mealRow(summary.recipes(for: greeting.mealType), greeting: greeting)
            favorites(summary.favorites)
            rediscover(summary.rediscover)
            browseByMeal(summary.mealCounts)
        }
    }

    private func actions(_ summary: HomeSummary, mealType: MealType) -> some View {
        let pool = summary.surprisePool(for: mealType)
        let layout = HomeActionTile.rowLayout(for: dynamicTypeSize)
        return layout {
            Button {
                isShowingEditor = true
            } label: {
                HomeActionTile(
                    title: "New Recipe",
                    subtitle: "Add one to your cookbook",
                    systemImage: "plus",
                    isProminent: true,
                    isWide: !summary.canSurprise
                )
            }

            if summary.canSurprise {
                Button {
                    surpriseRecipe = pool.recipes.randomElement()
                } label: {
                    HomeActionTile(
                        title: "Surprise Me",
                        subtitle: surpriseSubtitle(pool, recipeCount: summary.recipeCount),
                        systemImage: "dice"
                    )
                }
                .accessibilityHint("Opens a random recipe")
            }
        }
        .buttonStyle(.card)
        // Both tiles as tall as the taller one.
        .fixedSize(horizontal: false, vertical: true)
    }

    private func surpriseSubtitle(_ pool: HomeSummary.SurprisePool, recipeCount: Int) -> LocalizedStringResource {
        switch pool.mealType {
        case .breakfast: "Pick something for breakfast"
        case .lunch: "Pick something for lunch"
        case .dinner: "Pick something for dinner"
        case .snack: "Pick a snack"
        case .dessert: "Pick a dessert"
        case .drink: "Pick a drink"
        case nil: "Pick one of your \(recipeCount) recipes"
        }
    }

    /// Answers the greeting's question, like "What's for dinner?". Hidden when no recipe is for that meal.
    @ViewBuilder private func mealRow(_ recipes: [Recipe], greeting: Greeting) -> some View {
        if !recipes.isEmpty {
            section(greeting.mealTitle, seeAll: { navigation.showRecipes(.all, mealType: greeting.mealType) }) {
                recipeRow(recipes)
            }
        }
    }

    @ViewBuilder private func favorites(_ recipes: [Recipe]) -> some View {
        section("Favorites", seeAll: { navigation.showRecipes(.favorites) }) {
            if recipes.isEmpty {
                Label {
                    Text("Tap the heart on a recipe to keep it close at hand here.")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "heart")
                        .foregroundStyle(.secondaryAccent)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.surface, in: .rect(cornerRadius: 18))
            } else {
                recipeRow(recipes)
            }
        }
    }

    @ViewBuilder private func rediscover(_ recipes: [Recipe]) -> some View {
        if !recipes.isEmpty {
            section("Rediscover", subtitle: "Not opened in a month or more") {
                recipeRow(recipes)
            }
        }
    }

    /// Hidden until a recipe has a meal, since every tile would be empty.
    @ViewBuilder private func browseByMeal(_ counts: [MealType: Int]) -> some View {
        if !counts.isEmpty {
            section("Browse by Meal") {
                // Two side by side are too narrow for accessibility text sizes.
                let columns = dynamicTypeSize.isAccessibilitySize
                    ? [GridItem(.flexible())]
                    : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MealType.allCases) { mealType in
                        Button {
                            navigation.showRecipes(.all, mealType: mealType)
                        } label: {
                            MealTile(mealType: mealType, count: counts[mealType, default: 0])
                        }
                        .buttonStyle(.card)
                    }
                }
            }
        }
    }

    private func recipeRow(_ recipes: [Recipe]) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(recipes) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeCard(recipe: recipe)
                    }
                    .buttonStyle(.card)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        // Runs to the screen's edges, so it's clear the row scrolls.
        .contentMargins(.horizontal, margin, for: .scrollContent)
        .padding(.horizontal, -margin)
    }

    private var welcome: some View {
        VStack(spacing: 16) {
            Image(.launchLogo)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Your cookbook starts here")
                    .font(.display(.title2))
                    .accessibilityAddTraits(.isHeader)
                Text("Save the recipes you love, with their ingredients, steps and a photo, and find them here anytime.")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Button {
                isShowingEditor = true
            } label: {
                Text("Create Your First Recipe")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.surface, in: .rect(cornerRadius: 24))
    }

    private func section(
        _ title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        seeAll: (() -> Void)? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.display(.title2))
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    if let seeAll {
                        Button("See All", action: seeAll)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AuthService())
    .environment(RecipeRepository())
    .environment(RecipePhotoStore())
    .environment(Connectivity())
    .environment(AppNavigation())
}
