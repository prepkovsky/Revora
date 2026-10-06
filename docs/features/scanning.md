# Scanning

People take a photo of a recipe, or pick one from their library, and Revora fills in the editor for them. The app side is `Features/Editor/ScanRecipeView.swift` and `Services/RecipeScanner.swift`. The reading itself happens in the `scanRecipe` [Cloud Function](../functions.md).

## Starting a scan

Recipes' `+` is a menu: **New Recipe**, then **Scan a Recipe** with **Take Photo** (only when there's a camera) and **Choose from Library**. The library is `PhotosPicker`, which runs out of process and needs no photo library permission. The camera is `CameraPicker`, like the editor's.

## While it reads

`ScanRecipeView` opens as a sheet with the photo, a spinner and "Reading the recipe…". After 10 seconds, the line under it says long recipes can take up to a minute. **Cancel** closes the sheet. A scan that's still running is dropped, but the function has already counted it.

Before anything is sent:

- If the device is offline, it says so straight away instead of trying.
- The photo is loaded. One from iCloud can take a moment.
- `PhotoProcessor.prepareForScan` shrinks it off the main actor: longest side 2048 px, at most 1.5 MiB, no metadata. That's larger than a cover photo, so small print stays readable.

`RecipeScanner` then calls the function through `FirebaseFunctions` and waits up to 100 seconds, a little longer than the function's own 90.

## The result

The sheet turns into the editor, filled in as a new recipe (`RecipeEditorView(scanned:)`):

- A note at the top asks people to check the recipe before saving.
- The scanned photo isn't the cover photo. People add one with the photo tile as usual.
- The keyboard stays closed, unless the scan found no title.
- The draft is compared with an empty one, so **Cancel** asks to discard, like any new recipe with something in it.
- Nothing is saved until **Save**.

`RecipeDraft(scanned:)` turns the sections into the editor's rows: a section row for each named section, and its items under it.

## When it doesn't work

The error takes the spinner's place, with a title, the `ScanError` message and a way on. A failed scan also plays the error haptic.

| Error | Title | Buttons |
|---|---|---|
| Offline | You're Offline | **Try Again** (the same photo), **Choose Another Photo** |
| Timed out, OpenAI unavailable, unknown | Couldn't Read Recipe | **Try Again**, **Choose Another Photo** |
| Unreadable photo, or moderation turned it away | Can't Scan This Photo | **Try Another Photo** |
| No recipe in the photo | No Recipe Found | **Try Another Photo** |
| Daily limit | Daily Limit Reached, saying when scanning opens again | **Type It In Instead**, which opens an empty editor |
| Logged out, email not confirmed | Couldn't Read Recipe | **Done** |

A photo moderation turned away gets the same neutral wording as one that couldn't be read.

## Privacy

The photo goes through the function to OpenAI, and Revora doesn't keep it. What OpenAI does with it is in [Cloud Functions](../functions.md#reading-the-recipe) and the Privacy Policy.
