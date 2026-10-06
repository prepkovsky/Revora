# Editor

`RecipeEditorView` creates and edits recipes. It opens as a sheet from **New Recipe** in Recipes' `+` menu, Home's **New Recipe**, **Edit** on a recipe page, and filled in after a [scan](scanning.md). The code is in `Features/Editor/`.

## Layout

A native `Form`, styled in the app's colors, always in edit mode (like Contacts), so rows show delete and reorder controls:

1. **Photo:** a tile that opens Choose from Library, Take Photo or Remove Photo. Without a camera or a photo, it opens the library straight away.
2. **Title:** required. Save is disabled until it has something other than spaces.
3. **Meal:** chips for Breakfast, Lunch, Dinner, Snack, Dessert and Drink. A recipe can have several or none. They're saved in that order.
4. **Ingredients:** rows with an amount and a name, plus **Add Ingredient** and **Add Section**.
5. **Steps:** numbered rows, plus **Add Step** and **Add Section**.

On iPad the sheet uses page sizing, since a form sheet showed little more than the photo.

## Sections and bullet points

Each list is one flat list in the editor, with section rows (just a name) between the items. That way items can be dragged from one section to another. When saving, `RecipeDraft` groups the items under the section row above them.

- Ingredient sections are added at the end ("For the garnish" after the main list).
- The first step section added to a list that already has steps goes at the top, so those steps become its steps. Numbered sections need every step to be in one.
- A step can have bullet points. While typing a step, an **Add Bullet Point** button sits above the keyboard. Bullets live inside their step's row, so they move and delete with it.

## Return key

Return moves on, so a whole recipe can be typed without touching the screen:

- Title → the first ingredient (adding one if there are none) → its amount → its name → the next row. Return on a filled last row adds a new one.
- An empty last row is removed, and focus moves on: from ingredients to steps, and from the last step the keyboard closes.
- In a step with bullets, Return goes to its first bullet. In a bullet, it adds the next one. On an empty last bullet, it removes it and moves to the next step.
- A section name goes to that section's first item.

Rows emptied this way are removed in a `Task` after focus has moved. Removing them at once crashed: the multi-line field wrote back to a row that was already gone.

On iOS 27, Return in a multi-line text field submits instead of adding a line break. On older versions, and for pasted text, line breaks are stripped and treated as Return.

## Saving

- **Blank rows are dropped:** empty ingredients, steps and bullets, and unnamed section rows (their items join the section above). An ingredient with only an amount is kept.
- **Photos are saved first.** A picked photo is resized as soon as it's picked, so the preview and the upload both use the small version. On save it gets a new `photoID`, then the recipe is written pointing at it, then the old photo is deleted. A recipe never points at a photo that isn't there.
- **Edits start from the latest copy** of the recipe, so a favorite toggled meanwhile isn't undone.
- **Nothing is awaited.** The writes go to Firestore's local cache, so Save works offline and closes the sheet straight away.
- A second tap on Save while the sheet closes is ignored, so a new recipe can't be saved twice.

## Discarding

If anything changed, Cancel asks before discarding ("Discard this recipe?" or "Discard your changes?"), and swiping the sheet down is blocked. Changes are compared after trimming, so opening a recipe and closing it untouched doesn't ask. A picked, changed or removed photo counts as a change.

## Accessibility

VoiceOver can't reach the system's delete buttons in edit mode, so each row has **Move Up**, **Move Down** and **Delete** actions. The amount field reads "Amount of Flour", which also names the row's reorder handle.
