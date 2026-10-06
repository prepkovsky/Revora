# Testing

## Running the tests

```sh
xcodebuild -project Revora.xcodeproj -scheme Revora \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Or press ⌘U in Xcode. Any iPhone simulator on iOS 18 or later works. The run shuts the simulator down when it's done.

## What's tested

Unit tests live in `RevoraTests/` and use **Swift Testing**. They cover logic that doesn't need the network, and **never call Firebase**.

| Area | Tests |
|---|---|
| Models | `RecipeCodingTests` (the Firestore shape, older recipes without sections, photos or meals, unknown fields), `MealTypeTests` (raw values pinned, display order) |
| Editor | `RecipeDraftTests`: trimming, dropping blank rows, sections and bullets, step numbering, what counts as a change |
| Recipes tab | `RecipeFilterTests` (segments, the 3-day Recent window, meal and search), `RecipeSortingTests` |
| Home | `HomeSummaryTests` (every row and Surprise Me), `GreetingTests` (time of day, time zones) |
| Forms | `RegisterFormTests`, `LoginFormTests`, `ChangePasswordFormTests`, `ProfileTests` (name and change email) |
| Errors | `AuthErrorTests`, `RecipeErrorTests`, `PhotoErrorTests`: Firebase codes map to the right friendly message |
| Auth state | `AuthStateTests`, `SentVerificationsTests`, `EmailRateLimitTests` (cooldown, hourly cap, hashing, a clock turned back) |
| Photos | `PhotoProcessorTests`: sizes, aspect ratio, no upscaling, orientation, size limits, no location metadata, for cover photos and scans |
| Scanning | `ScanErrorTests` (every function error code, when the daily limit resets, connection failures), `ScannedRecipeTests` (the function's reply, unknown meals, the editor draft it fills in) |
| Other | `TimeoutTests`, `AppNavigationTests`, `AppearanceTests`, `LegalTextTests` (parsing and every page in the bundle), `HelpTopicTests`, `DisplayFontTests` (the fonts are registered) |

### Writing tests

- Put logic in small types that don't import Firebase (forms, filters, summaries, error mapping), so it can be tested without it.
- Pass in anything that changes: `now:` for dates, `UserDefaults(suiteName:)` for storage. Never use `.standard` in a test.
- Raw values that are saved (`MealType`, `Appearance`) are pinned by a test, since renaming one would lose data.
- The test target is **not** MainActor by default, unlike the app. `@Test(arguments:)` can't take main-actor values, so use plain values or separate `#expect`s.

## What isn't covered

On purpose:

- **Anything that needs Firebase:** `AuthService`, `RecipeRepository`, `RecipePhotoStore`, `RecipeScanner` and the security rules. The Cloud Functions have their own tests (see [Cloud Functions](functions.md#tests)). The Firebase Emulator Suite could test those, but it needs Node and Java, so it's left out for now.
- **Views and layouts.** There are no UI or snapshot tests.
- **`Connectivity`**, which wraps `NWPathMonitor`.

Those were checked by hand on the simulator and against the real Firebase project as each feature landed. After changing them, check by hand:

- sign up, confirm the email, log in, log out;
- create, edit, favorite and delete a recipe, with and without a photo;
- turn Wi-Fi off: the Offline badge shows, edits still save, and they sync when it's back;
- for rules changes, the Rules Playground (see [Data and security](data-and-security.md#publishing-the-rules));
- light and dark mode, the largest accessibility text size, and an iPad.
