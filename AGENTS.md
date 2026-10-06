# Revora

A simple iOS/iPadOS recipe app. Users sign up or log in with email and password, save their own recipes (title, ingredients, steps) and mark them as favorites.

This file is the short rule sheet. The details are in [`docs/`](docs/documentation.md): read the page for the area you're changing before you change it.

## Stack

- SwiftUI, iOS/iPadOS 18+ (deployment target), built with Xcode 27. Guard newer APIs with `#available`.
- **Swift 6** language mode with **default MainActor isolation** and approachable concurrency (set in build settings)
- Firebase via Swift Package Manager: **FirebaseAuth**, **FirebaseFirestore** and **FirebaseFunctions** only. Don't add other Firebase products without asking.
- No other third-party dependencies in the app.
- Cloud Functions in `functions/`: TypeScript on Node 22, with only `firebase-admin` and `firebase-functions`. OpenAI is called with plain `fetch`. See [Cloud Functions](docs/functions.md).

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

Build and test the Cloud Functions (run `npm install --prefix functions` once first):

```sh
npm --prefix functions test
```

The app needs `Revora/GoogleService-Info.plist` to build and run. It is gitignored on purpose. Never commit it, and never remove it from `.gitignore`.

## Project layout

```
Revora/
├── App/            App entry point, root view (auth vs. main tabs), navigation, appearance
├── Services/       AuthService, RecipeRepository, RecipePhotoStore, RecipeScanner (Firebase wrappers), Connectivity, error types
├── Models/         Recipe, RecipeSection, Ingredient, Step, MealType
├── Features/       One folder per screen area: Auth, Home, Recipes, Editor, Account
├── Components/     Shared reusable views
├── Resources/      Fonts, the in-app legal texts and open-source licences
└── Assets.xcassets
RevoraTests/        Unit tests (Swift Testing)
functions/          Cloud Functions (TypeScript): scanRecipe, with tests next to the code
docs/               Developer documentation
```

- `Revora/` and `RevoraTests/` are Xcode **synchronized folders**: new files and folders inside them are picked up automatically. Don't edit `project.pbxproj` to add source files.
- Only edit `project.pbxproj` for build settings or package changes, and keep edits minimal.

## Architecture

See [Architecture](docs/architecture.md) and [Data and security](docs/data-and-security.md).

- `@Observable` models and services, injected through the SwiftUI environment.
- Views don't talk to Firebase directly. They go through `AuthService`, `RecipeRepository`, `RecipePhotoStore` and `RecipeScanner`.
- One `NavigationStack` per tab. Native `TabView` with three tabs: Home, Recipes and Account. New recipes open the editor as a sheet.
- Recipe and photo writes go to Firestore's local cache and aren't awaited, so they work offline. Awaited Firebase calls go through `withTimeout`.
- Accounts must confirm their email before the app opens (`AuthService.state` is `.unverified` until then), and the security rules require it too.
- All photo access goes through `RecipePhotoStore`. Photos live in Firestore and never change: a new photo gets a new `photoID`.
- The Firestore shape is in [Data and security](docs/data-and-security.md#firestore-layout). Keep older recipes decoding when you change it, and cover both shapes in `RecipeCodingTests`.
- The security rules are in `firestore.rules`. They're deployed by hand in the Firebase console, so after every change, say that they need publishing there.
- The OpenAI key lives only in the Firebase secret `OPENAI_API_KEY`. Never put it in the app, a file or the repo. After every change in `functions/`, say that it needs deploying (`firebase deploy --only functions`).

## Conventions

- Match the existing code style. Keep comments sparse; explain *why*, not *what*.
- Use Swift concurrency (`async/await`) rather than completion handlers where Firebase offers both.
- Show user-facing errors as friendly messages, not raw Firebase errors.
- Destructive actions always ask first and say they can't be undone, swipe actions too.
- Use the app's color sets (`.secondaryText`, not `.secondary`) and `Font.display` for titles. See [Design](docs/design.md).
- Unit test logic that doesn't need the network (validation, error mapping, model coding, sorting/filtering) with Swift Testing. Tests never call real Firebase.
- Don't use `@unchecked Sendable` or `nonisolated(unsafe)` to silence concurrency errors without explaining why it's safe.

## Working in this repo

- Work in small stages. Build after each change and make sure there are no new warnings.
- If a requirement is unclear, ask before starting.
- When behavior changes, update the matching page in `docs/` and Help's answers (`HelpTopic.all`) in the same change.
- Commit or push only when asked.
- For commit messages, use the `commit-message` skill if it's available, unless told otherwise. Without it: short imperative subject, blank line, brief body.
