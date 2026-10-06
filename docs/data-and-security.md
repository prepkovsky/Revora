# Data and security

What Revora stores, where, and who can reach it.

## Firestore layout

Everything a user saves lives under their own user ID:

```
users/{uid}/recipes/{recipeId}
  title, ingredientSections [{ title?, items [{ name, quantity }] }],
  stepSections [{ title?, items [{ text, bullets [String] }] }], mealTypes [String],
  photoID?, isFavorite, createdAt, updatedAt, lastOpenedAt?

users/{uid}/recipes/{recipeId}/photos/{photoID}       data: Bytes (JPEG, ≤ 500 KiB)
users/{uid}/recipes/{recipeId}/thumbnails/{photoID}   data: Bytes (JPEG, ≤ 100 KiB)
```

There's no `users/{uid}` document itself. The name lives in Firebase Auth's `displayName`, not in Firestore.

One more collection belongs to the `scanRecipe` Cloud Function, not the app:

```
scanUsage/{uid}   day, count, expiresAt   (today's recipe scans)
```

The rules don't match it, so the app can't read or change it. See [Cloud Functions](functions.md#daily-limit).

### Recipes

- **IDs** are made on the device (`newRecipeID()`), so a photo can be saved under a recipe before the recipe itself.
- **Sections** split a recipe into named parts. `title` is missing for the items before the first named section, and for recipes without sections. Step sections are numbered on screen, and their steps start again at 1.
- **Quantities** are free text ("200 g", "a pinch").
- **`mealTypes`** holds `MealType` raw values (`breakfast`, `lunch`, `dinner`, `snack`, `dessert`, `drink`), in that order. It's missing on older recipes, and unknown values are skipped when decoding, so a newer app version can add meals without breaking older ones.
- **Dates** are the device's clock, stored as Timestamps. `updatedAt` changes when a recipe is saved from the editor. Favoriting and opening update only `isFavorite` and `lastOpenedAt`, so they don't count as edits.
- **The document ID isn't a field.** It's passed to the decoder in `userInfo[Recipe.documentIDKey]`, and decoding throws without it. A document that doesn't decode is skipped and logged, so one bad recipe doesn't hide the rest.

### Older recipes

Recipes saved before sections existed have `ingredients [{ name, quantity }]` and `steps [String]` instead of the two section fields. They're read as one untitled section each, and written in the new shape the next time they're saved. Both shapes are covered by `RecipeCodingTests`.

## Photos

Cover photos live in Firestore, not Cloud Storage, so the project stays on the free Spark plan (Cloud Storage needs the paid Blaze plan). Each photo is two documents with a single `data` field: a full-size JPEG and a thumbnail. They're separate documents so lists and cards only download thumbnails.

`PhotoProcessor` prepares them on the device, off the main actor:

| | Longest side | Target size | Rules allow |
|---|---|---|---|
| Full size | 1280 px | ≤ 450 KiB | 500 KiB |
| Thumbnail | 400 px | ≤ 90 KiB | 100 KiB |

It steps the JPEG quality down from 0.8 to 0.5, then shrinks the image by a fifth and tries again, until it fits. It never upscales, applies the EXIF orientation, and writes no metadata, so a photo's location never leaves the device.

- **Photos never change.** A new photo gets a new `photoID`. The editor saves the new photo first, then the recipe pointing at it, then deletes the old photo. So a recipe never points at a photo that isn't there, and the device's cache never goes stale.
- **Loading** tries the device's Firestore cache first, then the server, and keeps decoded images in memory for scrolling.
- **All photo access goes through `RecipePhotoStore`.** Recipes only hold the `photoID`, so a later move to Cloud Storage would change that one type plus a one-time migration.

## Security rules

The source is [`firestore.rules`](../firestore.rules). In short:

- People can only read and write recipes under their own `uid`, and only once their email is confirmed (`request.auth.token.email_verified`). Everything else is denied by default.
- Photo and thumbnail documents can only be **created or deleted**, never updated. A new one must have exactly one field, `data`, holding bytes within the size limit above.
- Recipe fields aren't checked by the rules, so adding a field to `Recipe` doesn't need a rules change.

### Publishing the rules

The rules are **deployed by hand**. After every change to `firestore.rules`:

1. Open the Firebase console → **Firestore Database** → **Rules**.
2. Paste in the whole file and **Publish**.
3. Check the change in the **Rules Playground**: your own recipe allowed, another user's path denied, and for photos, an update or a non-bytes `data` denied.

`firebase.json` only configures the [Cloud Functions](functions.md), so `firebase deploy` never touches the rules.

## On the device

| What | Where | Why |
|---|---|---|
| A copy of the user's recipes and photos | Firestore's local cache | Offline use and fast loading |
| Decoded photos | In memory (`NSCache`) | Smooth scrolling. Cleared when the account is deleted. |
| Appearance | `UserDefaults`, `appearance` | It's about this device, not the account |
| Accounts a confirmation link went to | `UserDefaults`, `verificationSentUserIDs` | So a relaunch doesn't offer to send a link that's already on its way |
| Recent email requests | `UserDefaults`, `emailSends.<kind>` | The app's email limits. Addresses are stored as SHA-256 hashes, and only the last hour is kept. |
| The session | Keychain (Firebase Auth) | Staying signed in |

The privacy manifest (`Revora/PrivacyInfo.xcprivacy`) declares the `UserDefaults` use (reason `CA92.1`) and the data the app collects. See [Release](release.md#privacy).

## Free plan limits

The project runs on Firebase's free Spark plan, so it can't run up a bill. Its daily allowances are shared by everyone using the app:

- **Firestore:** 50,000 reads, 20,000 writes and 20,000 deletes a day, and 1 GiB stored. When the quota runs out, loads fail with `resourceExhausted`, which the app shows as "Revora has reached its limit for today".
- **Emails:** about 150 password resets and 1,000 verification or email-change emails a day, for the whole project. See [Auth](features/auth.md#email-limits) for how the app holds back.
- **Sign-ups:** Firebase allows 100 new accounts an hour from one IP address. The console can only raise that for a while, not lower it.

### Known gaps

- **No write limits in the rules.** Rules can't count requests, so only the free plan's daily quota limits how much an account writes. App Check, which needs a paid Apple Developer account, makes Firebase accept requests only from the real app (see [Release](release.md#app-check)).
- **Orphaned photos.** If deleting a recipe's photo fails, the photo documents stay behind under a deleted recipe. Nothing points at them, but deleting the account doesn't find them either, because the app can't list the subcollections of a deleted document. Finding them would need a collection-group query and a rules change.
