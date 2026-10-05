# Design

How Revora looks, as built: colors, fonts, shared components, and how screens handle loading, empty and error states. Use what's here before adding something new.

## Colors

Every color is a color set in `Assets.xcassets`, with light, dark and Increase Contrast variants. Use them by name (`.appBackground`, `.secondaryText`, `.tint`), never hard-coded values.

| Color set | Light | Dark | Used for |
|---|---|---|---|
| `AccentColor` | `#40534C` deep green | `#D6BD98` almond | Tint: buttons, links, toggles, picked chips |
| `AccentForeground` | `#FFFFFF` | `#1A3636` | Text and icons on the accent, like the primary button's label |
| `SecondaryAccent` | `#677D6A` sage | `#677D6A` | Symbols and quieter accents: placeholders, meal icons, the favorite swipe |
| `AppBackground` | `#F5EEE5` cream | `#101C1C` | Every screen's background, and the launch screen |
| `Surface` | `#FFFFFF` | `#1A2C2C` | Cards, list rows and form fields on the background |
| `SecondaryText` | `#5C6660` | `#99A39E` | Secondary text, used instead of the system's `.secondary` |
| `CardShadow` | black 6% | clear | Home's card shadows. None in dark mode, where cards are already lighter than the background. |

- **`SecondaryText` replaces `.secondary` everywhere.** The system gray measured about 3.3:1 on `AppBackground`, below the 4.5:1 that small text needs. `SecondaryText` is 5.2:1 or more in both modes. Section headers, footers and empty-state descriptions are drawn in system gray by default, so they set it explicitly.
- **The accent flips in dark mode**, from deep green to almond. White text on almond would be unreadable, which is why `AccentForeground` exists and why the primary button doesn't use the system's label color.
- Some things stay system gray because SwiftUI doesn't let them change: placeholders, chevrons, and a menu picker's value.

## Fonts

- **Titles and headings** use Fraunces Soft, a serif with soft, rounded details: navigation bar titles, the recipe title, section headings, empty-state titles, auth screen headings and Home's greeting.
- **Everything else** stays in SF Pro: body text, list rows, ingredients, steps and fields, which read better at small sizes.

The font files (`FrauncesSoft-SemiBold.ttf` and `FrauncesSoft-Italic.ttf` in `Resources/Fonts/`) are Fraunces with its soft serifs and weight built in. They keep the optical size axis, so large titles get finer details. They're registered in `Info.plist` under `UIAppFonts`. Fraunces is by Undercase Type, under the SIL Open Font License (`Fraunces-OFL.txt` next to the fonts, and listed in Acknowledgments).

Use the helpers in `Components/DisplayFont.swift`, never a font name:

```swift
Text("Good evening").font(.display(.largeTitle))
Text("What's for dinner?").font(.display(.title2, italic: true))
Text(greeting).font(.display(size: 40, relativeTo: .largeTitle))
```

They scale with Dynamic Type like the text style they're relative to. SwiftUI's font modifiers don't reach navigation bar titles, so `DisplayFont.applyToNavigationBars()` sets those once, from `RootView`.

## Shapes and spacing

- Home's cards and tiles have rounded corners of 18–24 pt, form fields 12 pt and list thumbnails 10 pt.
- Forms and auth screens are capped at 480 pt wide, and Home, the recipe page and legal pages at 700 pt, so lines stay readable on iPad.
- Tap targets are at least 44 × 44 pt. Small buttons like See All and Show Password get padding to reach it.

## Components

Shared views live in `Components/`.

| Component | What it's for |
|---|---|
| `.buttonStyle(.primary)` | A screen's main action: filled, large, semibold, labelled in `AccentForeground`. One per screen. |
| `ProgressButtonLabel` | A primary button's label that turns into a spinner while working. The spinner waits 400 ms before appearing and then stays at least 500 ms, so quick requests don't flash it. |
| `FormField` | A labelled input with a hint or error underneath. The label stays visible while typing, unlike a placeholder. Used on the auth and account screens. |
| `PasswordField` | A secure field with a button to show what was typed. |
| `ErrorMessage` | An inline error with an icon (so it doesn't rely on color alone) and an optional action, like **Reset Password**. |
| `ConfirmationMessage` | What a form turns into once it's done: icon, title, what happens next, and a way on. |
| `EmailWaitNote` | When another email link can be sent, counting down. |
| `EmptyStateLabel` | An empty state's title in the display font, inside `ContentUnavailableView`. |
| `RecipePhotoView` | A recipe's photo, or a `fork.knife` placeholder while it loads or when there isn't one. It fills whatever frame it's given. |
| `MealTypeChip` | A meal people can pick. A picked chip is filled and shows a checkmark, so the difference doesn't rely on color. |
| `FlowLayout` | Wraps chips onto new rows like words, so they still fit at large text sizes. |
| `.offlineIndicator()` | The quiet Offline badge in the navigation bar. |
| `.recipeErrorAlert(_:error:)` | An alert for a failed recipe action. |

The recipe editor is the exception to `FormField`: it's a native `Form`, because it needs the system's add, delete and reorder controls. It's styled with `Surface` rows on `AppBackground`.

## Loading, empty and error states

**Loading**

- Nothing appears for the first 400 ms, so fast loads don't flash anything (`DelayedProgressView`, the skeletons and `ProgressButtonLabel` all wait).
- Home and Recipes show **skeletons** shaped like their content instead of a spinner, then crossfade to it. `.shimmering()` sweeps a slow band of light across them in the reading direction, and stops with Reduce Motion. VoiceOver hears "Loading recipes" once.
- Buttons ignore taps while their request runs.

**Empty**

- Use `ContentUnavailableView` with an `EmptyStateLabel`, a sentence on what would appear here, and, where it helps, one button that fixes it (**Create Your First Recipe**, **Show All Meals**).
- Each filter gets its own wording, so an empty Favorites doesn't look like lost recipes.
- On Home, rows with nothing to show hide themselves.

**Errors**

- Always a friendly message from the error type (`AuthError`, `RecipeError`, `PhotoError`), never Firebase's.
- Form errors show inline under the field they're about, with `ErrorMessage`.
- Failed actions without a form (delete, favorite) show an alert.
- If recipes can't load, `RecipesLoadFailedView` takes their place with **Try Again**, instead of a spinner that never ends or an empty state that suggests they're gone.
- Offline isn't an error: recipes keep working, so the badge stays quiet.

**Destructive actions** always ask first and say they can't be undone, including the delete swipe. Log Out is the one exception, since nothing is lost.

## Accessibility

- Text uses text styles, so everything scales with Dynamic Type. At accessibility sizes, rows that sit side by side stack instead (with `AnyLayout`), and long fields wrap.
- Every control has a VoiceOver label, including text fields with a prompt, which VoiceOver doesn't read on its own. Recipe photos are decorative and hidden from VoiceOver; the title next to them says the same.
- Meaning never relies on color alone: errors have an icon, picked chips a checkmark, favorites a filled heart.
- The color sets have Increase Contrast variants, and the shimmer stops with Reduce Motion.
