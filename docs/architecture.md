# Architecture

Revora is a SwiftUI app in Swift 6 language mode. Views read `@Observable` services from the environment, and only those services talk to Firebase.

## Folders

```
Revora/
├── App/            Entry point, root view, tab bar, navigation and appearance
├── Services/       Firebase wrappers, connectivity, error types, email limits, timeouts
├── Models/         Recipe, RecipeSection, Ingredient, Step, MealType
├── Features/       One folder per screen area: Auth, Home, Recipes, Editor, Account
├── Components/     Shared views and modifiers
├── Resources/      Fonts, the in-app legal texts and open-source licences
├── Assets.xcassets Colors, app icon and launch logo
├── Info.plist      Fonts, launch screen, camera usage text
└── PrivacyInfo.xcprivacy
RevoraTests/        Unit tests (Swift Testing)
functions/          Cloud Functions in TypeScript: scanRecipe
firebase.json       Firebase CLI config, for deploying the functions only
firestore.rules     Firestore security rules, published by hand
```

`Revora/` and `RevoraTests/` are Xcode **synchronized folders**: new files and folders inside them are part of the target straight away. Don't edit `project.pbxproj` to add files. Only touch it for build settings or packages.

## Services

`RevoraApp` creates one of each and puts them in the environment. Views never import Firebase.

| Service | What it does |
|---|---|
| `AuthService` | The auth state, and everything to do with the account: register, log in, log out, confirm email, reset password, name, email and password changes, deleting the account. Maps Firebase errors to `AuthError`. |
| `RecipeRepository` | A live listener on the signed-in user's recipes, plus create, update, favorite, mark opened and delete. Maps errors to `RecipeError`. |
| `RecipePhotoStore` | Resizes, saves, loads and deletes cover photos, with an in-memory cache. Maps errors to `PhotoError`. |
| `Connectivity` | Whether the device is online, for the offline badge and for retrying photos. Never blocks anything. |

Smaller pieces in `Services/`:

- `PhotoProcessor` turns a picked image into a full-size JPEG and a thumbnail (see [Data and security](data-and-security.md#photos)).
- `EmailRateLimit` and `SentVerifications` keep a little state in `UserDefaults` about emails the app has asked Firebase to send (see [Auth](features/auth.md#email-limits)).
- `withTimeout` gives up on a request after 15 seconds (see [Concurrency](#concurrency)).

Each error type has a friendly `message`. Screens show that, never the raw Firebase error.

## Root flow

`RootView` switches on `AuthService.state`:

| State | Shows |
|---|---|
| `.loading` | The launch logo, while Firebase restores the session from the keychain |
| `.signedOut` | `AuthFlow`: Login, with Register and Reset Password pushed from it |
| `.unverified` | `VerifyEmailView`, until the email is confirmed |
| `.signedIn` | `MainTabView`, and the recipe listener starts |

The recipe listener runs in a `.task(id:)` keyed on the user ID and a retry counter. Signing out cancels the task, which stops the listener and clears the recipes. Trying again after a failed load bumps the counter, which starts a new listener.

`RootView` also:

- applies the Appearance setting once with `.preferredColorScheme`, so sheets and the auth screens follow it too;
- calls `AuthService.refreshUser()` whenever the app becomes active, so an email confirmed or changed from a link takes effect straight away;
- sets the navigation bar title fonts (in its `init`, because doing it in the app's `init` loses the accent color).

## Navigation

- `MainTabView` is a native `TabView` with three tabs: **Home**, **Recipes** and **Account**. Each has its own `NavigationStack`.
- `AppNavigation` holds the selected tab and the Recipes tab's filter and meal. It lives in the environment, so Home's "See All" and meal tiles can switch to Recipes with the right filter (`showRecipes(_:mealType:)`).
- New recipes come from the `+` button in the Recipes navigation bar and Home's **New Recipe** tile. Both open `RecipeEditorView` as a sheet. Editing opens the same sheet with the recipe.
- The recipe detail view is pushed with `NavigationLink(value:)` and looks its recipe up live by ID, so it updates as the listener does.

## Concurrency

- Swift 6 language mode with **default MainActor isolation** and approachable concurrency, set in build settings. App code runs on the main actor unless it says otherwise.
- Types that are used off the main actor, like the models, `PhotoProcessor` and `EmailRateLimit`, are marked `nonisolated`.
- Firebase calls use `async`/`await`, not completion handlers, where Firebase offers both. Listeners are `AsyncSequence`s (`Auth.auth().authStateChanges`, `Query.snapshots`) that run for as long as the task that started them.
- Recipe and photo **writes aren't awaited.** They go to Firestore's local cache straight away and sync in the background, so saving works offline. A write the server later rejects is only logged, and the listener rolls it back. The exception is deleting the account, which waits for the server (see [Account](features/account.md#delete-account)).
- Awaited Firebase calls go through `withTimeout` (15 seconds). Firebase waits up to a minute on a stalled connection, and its requests can't be cancelled, so the timeout races the request with a timer instead of using a task group. A request given up on may still finish later, so it's only used where that's harmless.
- Don't use `@unchecked Sendable` or `nonisolated(unsafe)` to silence errors without explaining why it's safe.

## Offline

Firestore keeps a copy of the user's recipes on the device, so the app keeps working offline: recipes open, edits save, and everything syncs once the connection is back.

- A quiet **Offline** badge sits in the navigation bar of each tab root. Tapping it explains that changes will sync.
- Photos load from the device's cache first. One that hasn't been downloaded shows the placeholder, and loads once the device is back online.
- Account actions (log in, email changes, deleting the account) need a connection and say so.
- If the recipe listener fails (for example when the free plan's daily quota is used up), Home and Recipes show "Couldn't Load Recipes" with **Try Again**, instead of loading forever.

`NWPathMonitor` doesn't always report the connection coming back (the Simulator's never does), so while offline, `Connectivity` starts a fresh monitor every 3 seconds.
