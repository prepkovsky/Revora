# Recipes

The Recipes tab and the recipe page. The code is in `Features/Recipes/`.

## The list

At the top, three segments and a row of meal chips:

| Segment | Shows |
|---|---|
| **Recent** | Recipes opened in the last 3 days, most recently opened first |
| **All** (the default) | Every recipe, A to Z |
| **Favorites** | Favorites, A to Z |

- **Recent means opened.** Creating, editing or favoriting a recipe doesn't count, so a new recipe appears in Recent once it's opened. The 3-day window is checked when the list redraws, so a recipe can stay a little longer, until the list next updates.
- **Meal chips** narrow any segment to one meal. Tapping the picked chip again clears it. The row scrolls to the picked chip, since Dessert and Drink start off screen.
- **Search** (pull down) matches titles within the current segment and meal, ignoring case and accents.
- **Sorting** uses `localizedStandardCompare`, so "Crème" sorts with "Creme" and "Recipe 10" after "Recipe 9". Ties fall back to the creation date and then the ID, so the order never jumps.

The segment and meal live in `AppNavigation`, so Home can open the tab with a filter already set. `RecipeFilter` and `RecipeSorting` hold the logic and are unit tested.

### Rows

Each row shows a 56 pt thumbnail (or a placeholder, so titles line up), the title, and a short summary like "6 ingredients · 5 steps". Favorites get a small heart.

- **Swipe right** to favorite or unfavorite. A full swipe works, since swiping again undoes it.
- **Swipe left** to delete. It always asks first and says it can't be undone. The button is tinted red rather than using the destructive role, because that role slides the row away before the confirmation.

### Empty states

Each case gets its own message: no recipes at all (with **Create Your First Recipe**, and no segments or search), nothing in Recent, no favorites, nothing for a meal (with **Show All Meals**), and no search matches.

## The recipe page

`RecipeDetailView` shows the cover photo (only when there is one), the title, the meal types, an **Ingredients** card and a **Steps** card.

- Section names are headings inside each card. Step sections are numbered ("1. Make the dough"), and their steps start again at 1. Bullet points are indented under their step.
- The navigation bar has a heart to favorite and **Edit**, which opens the editor as a sheet. **Delete Recipe** is at the bottom, and asks first.
- Opening the page sets `lastOpenedAt`, which drives Recent, Continue Cooking and Rediscover. It only updates that field, so opening doesn't count as an edit.
- The page looks the recipe up live by ID. If it's deleted elsewhere, the page says "Recipe Not Found". After deleting from this page, it keeps showing the recipe while it closes, so that message never flashes.
- The text is kept to a 700 pt column on iPad. At accessibility sizes, an ingredient's amount sits above its name, and a step's number above its text.

## Deleting

The recipe document goes first, then its photo documents, because Firestore doesn't delete subcollections with their document. If the photo delete fails, it's only logged: nothing points at the photo anymore. See [Known gaps](../data-and-security.md#known-gaps).
