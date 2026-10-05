# Home

The first tab: a greeting and the recipes most worth opening right now. The code is in `Features/Home/`. `HomeSummary` works out what to show and is unit tested. The views only lay it out.

## From top to bottom

1. **Header:** today's date, then "Good evening, Sam" in the display font, then an italic prompt ("What's for dinner?"). It updates every minute, so it changes while Home stays open. Once it scrolls under the bar, a small version fades into the navigation bar.
2. **Quick actions:**
   - **New Recipe** opens the editor.
   - **Surprise Me** opens a random recipe. It shows once there are at least 2 recipes.
3. **Continue Cooking:** the recipe opened most recently, with its photo and when it was opened. Hidden until a recipe has been opened.
4. **For Dinner** (or For Breakfast, For Lunch, Midnight Snacks): recipes tagged for the current meal. See All opens Recipes filtered to that meal.
5. **Favorites:** most recently opened first. See All opens Recipes → Favorites. With no favorites, a small card explains how to add one.
6. **Rediscover:** recipes not opened in 30 days or more (or never, and added that long ago), forgotten longest first.
7. **Browse by Meal:** a tile for each meal with its recipe count. A tap opens Recipes filtered to that meal.

The rows show up to 6 recipes each (`HomeSummary.rowLimit`), and a row hides itself when it has nothing to show. A new account sees a welcome card with **Create Your First Recipe** instead.

## Time of day

`Greeting` decides the greeting, the prompt, the meal row and Surprise Me's meal from the hour:

| Hours | Greeting | Meal |
|---|---|---|
| 5:00–11:59 | Good morning | Breakfast |
| 12:00–16:59 | Good afternoon | Lunch |
| 17:00–21:59 | Good evening | Dinner |
| 22:00–4:59 | Good evening | Snack |

Late night still says "Good evening", because "Good night" is a goodbye.

## Surprise Me

It picks from recipes tagged for the current meal. If there are none, it picks from all recipes, and its subtitle says so ("Pick one of your 4 recipes" instead of "Pick something for dinner").

It leaves out the Continue Cooking recipe, which is already on screen, but only when there's another choice. Otherwise, once the only dinner recipe had been opened, Surprise Me would skip it for an untagged one.

## Loading

While the recipes load, Home shows a skeleton of the tiles and the Continue Cooking card instead of a spinner. It appears after 400 ms, so fast loads don't flash it. If loading fails, Home shows "Couldn't Load Recipes" with **Try Again**.

## Layout

The content is capped at 700 pt wide for iPad. At accessibility text sizes, the action tiles and meal tiles stack, and the recipe cards stop at 260 pt wide so the next one still peeks in.
