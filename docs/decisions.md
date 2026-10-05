# Decisions

The main choices behind Revora and why they were made. Check here before changing one of them.

## Platform and tools

- **iOS and iPadOS 18 and later**, built with Xcode 27. That keeps older devices supported. Newer APIs are guarded with `#available`.
- **Swift 6 with default MainActor isolation.** Turned on while the project was empty, when it cost nothing. App code runs on the main actor unless it says otherwise, which removes most concurrency noise in a SwiftUI app.
- **Only FirebaseAuth and FirebaseFirestore**, and no other dependencies. Each extra Firebase product is a deliberate choice, so ask before adding one.
- **`GoogleService-Info.plist` stays out of git.** It holds no real secret, since the rules protect the data, but keeping it out stops key scanners from flagging the repo. The cost is that a fresh clone needs the file added before it builds.
- **The rules are published by hand** in the Firebase console. There's one small rules file and no other Firebase config, so the Firebase CLI isn't set up.

## Data

- **Photos live in Firestore, not Cloud Storage.** Cloud Storage needs the paid Blaze plan, which needs a card on file. Firestore keeps the project on the free plan, at the cost of smaller photos (documents max out at 1 MiB). All photo access goes through `RecipePhotoStore`, so moving to Cloud Storage later means one new implementation and a one-time migration.
- **One cover photo per recipe.** It covers most of the value (list rows, Home cards, the recipe page) with one picker. A gallery or photos per step can come later.
- **Photos never change.** A new photo gets a new ID. The device's cache never goes stale, and replacing one is "save new, point at it, delete old".
- **Photos are resized on the device.** Small files upload quickly on cellular, keep usage within the free plan, and re-encoding drops location metadata.
- **Photos load through the SDK, never download URLs.** A download URL works for anyone who has it and skips the rules. Recipes are private.
- **Writes aren't awaited.** Firestore saves to the device and syncs in the background. Awaiting the server would leave Save spinning forever offline. Deleting the account is the one exception (see [Account](features/account.md#delete-account)).
- **Recipe IDs are made on the device**, so the editor knows the ID before saving, and a photo can be saved under it first.
- **The recipe ID isn't a stored field.** `@DocumentID` makes the ID optional and ignores IDs set before saving, which clashes with making them on the device. The ID is passed to the decoder instead.
- **Opening and favoriting don't count as edits.** They update only `lastOpenedAt` and `isFavorite`, so `updatedAt` means "last edited".
- **Sections are stored, not formatted text.** Recipes stay structured, and older recipes without sections still read as one untitled section.
- **Meal types are a fixed set**, not free-form tags. Six meals cover what Home and Surprise Me need, with no tag management.
- **The name lives in Firebase Auth** (`displayName`), not Firestore, so it needs no rules and no extra document.
- **Appearance is saved on the device**, not in the account. It's about the screen in front of you.

## Accounts

- **Email and password only.** Sign in with Apple may come later.
- **Passwords need 8 characters**, stricter than Firebase's 6.
- **The email must be confirmed before the app opens**, and the rules check it too. Recipes are then always tied to an address their owner can get back into. It's confirmed once, with Firebase's link. A code in the email would need Cloud Functions and an email service on the paid plan, so it was skipped.
- **Email changes use Firebase's verify-before-update flow.** The old `updateEmail` is deprecated, and changing the email without proving the new address would let an account move to an address its owner doesn't control. The downside, logging out everywhere, comes from Firebase.
- **The app never reveals which emails have accounts**: one message for a wrong email or password, and password reset always says "if there's an account".
- **Log Out doesn't ask.** Nothing is lost, and you log back in with the same details. Everything destructive does ask, and says it can't be undone.

## Limits

- **The app limits how often it asks for emails** (60 seconds per address, and a few per hour). The free plan's reset emails are shared by everyone, so a few taps shouldn't use them up.
- **No log-in backoff in the app.** Firebase's own lockout runs on its server, so it applies however the request arrives.
- **No rate limits in the Firestore rules.** Rules can't count requests. A gap between writes or a recipe cap would need extra documents kept in step with every write, doubling the writes for little gain. **App Check** is the real fix, and it waits for a paid Apple Developer account (see [Release](release.md#app-check)).
- **Real limits belong on the server.** The app's own limits stop accidental repeats. Firebase's limits and App Check do the rest.

## Interface

- **A native `TabView` with three tabs.** It's the only way to get the system's tab bar look, its animations and iPad behavior for free. The iPad sidebar style was tried, but it just repeated the three tabs over an empty panel.
- **New recipes come from a `+` in the Recipes bar**, not a tab. Tabs are for places, and a tab that opens a sheet would need a workaround.
- **Recent means opened in the last 3 days.** Creating and editing don't count. It's about what you've been cooking, not what you've been typing.
- **The editor is a native `Form`**, unlike the auth screens. It needs the system's add, delete and reorder controls.
- **Each recipe list is flat in the editor**, with section rows between items, so items can be dragged between sections.
- **Fraunces for titles, SF Pro for everything else.** A serif gives the app a cookbook feel, while body text stays easy to read at small sizes.
- **A custom secondary text color.** The system's gray didn't reach 4.5:1 on the cream background.
- **Skeletons instead of spinners** where content loads, so the screen doesn't jump when it arrives.

## Repository

- **No licence: all rights reserved.** The app may go on the App Store, so the code isn't open source.
- **Documentation stays as Markdown files in `docs/`**, with no website.
