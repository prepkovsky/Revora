# Revora

A simple iOS/iPadOS recipe app. Users sign up or log in with email and password, save their own recipes (title, ingredients, steps) and mark them as favorites.

## Stack

- SwiftUI, iOS/iPadOS 18+ (deployment target), built with Xcode 27. Guard newer APIs with `#available`.
- **Swift 6** language mode with **default MainActor isolation** and approachable concurrency (set in build settings)
- Firebase via Swift Package Manager: **FirebaseAuth** and **FirebaseFirestore** only. Don't add other Firebase products without asking.
- No other third-party dependencies.

## Build

```sh
xcodebuild -project Revora.xcodeproj -scheme Revora -sdk iphonesimulator \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Run unit tests (use any installed iPhone simulator):

```sh
xcodebuild -project Revora.xcodeproj -scheme Revora \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

If Xcode is open and resolving packages at the same time, add `-clonedSourcePackagesDirPath <tmp dir>` to avoid cache conflicts.

The app needs `Revora/GoogleService-Info.plist` to build and run. It is gitignored on purpose. Never commit it, and never remove it from `.gitignore`.

## Project layout

```
Revora/
├── App/            App entry point, root view (auth vs. main tabs)
├── Services/       AuthService, RecipeRepository (Firebase wrappers)
├── Models/         Recipe, Ingredient
├── Features/       One folder per screen area: Auth, Home, Recipes, Editor, Settings
├── Components/     Shared reusable views
└── Assets.xcassets
RevoraTests/        Unit tests (Swift Testing)
```

- `Revora/` and `RevoraTests/` are Xcode **synchronized folders**: new files and folders inside them are picked up automatically. Don't edit `project.pbxproj` to add source files.
- Only edit `project.pbxproj` for build settings or package changes, and keep edits minimal.

## Architecture

- `@Observable` models and services, injected through the SwiftUI environment.
- Views don't talk to Firebase directly. They go through `AuthService` and `RecipeRepository`.
- One `NavigationStack` per tab.
- Tab bar: native `TabView` with three tabs: Home, Recipes and Settings. New recipes are created from a `+` button in the Recipes navigation bar, which opens the recipe editor as a sheet.

### Firestore data

```
users/{uid}/recipes/{recipeId}
  title, ingredients [{ name, quantity }], steps [String],
  isFavorite, createdAt, updatedAt, lastOpenedAt?
```

Security rules: users can only read and write under their own `users/{uid}`.

## Conventions

- Match the existing code style. Keep comments sparse; explain *why*, not *what*.
- Use Swift concurrency (`async/await`) rather than completion handlers where Firebase offers both.
- Show user-facing errors as friendly messages, not raw Firebase errors.
- Unit test logic that doesn't need the network (validation, error mapping, model coding, sorting/filtering) with Swift Testing. Tests never call real Firebase.
- Don't use `@unchecked Sendable` or `nonisolated(unsafe)` to silence concurrency errors without explaining why it's safe.

## Working in this repo

- Work in small stages. Build after each change and make sure there are no new warnings.
- If a requirement is unclear, ask before starting.
- Commit or push only when asked.
- For commit messages, use the `commit-message` skill if it's available, unless told otherwise. Without it: short imperative subject, blank line, brief body.
