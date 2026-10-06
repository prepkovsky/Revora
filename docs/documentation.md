# Revora documentation

Developer documentation for Revora, a recipe app for iPhone and iPad built with SwiftUI and Firebase. For what the app does, see the [README](../README.md).

## Start here

1. [Getting started](getting-started.md): set up Firebase, build, run and test.
2. [Architecture](architecture.md): folders, services, navigation, concurrency and offline.
3. [Data and security](data-and-security.md): what's stored in Firestore, photos, the security rules and how to publish them, and the free plan's limits.

## Features

How each part of the app behaves, including what the code doesn't make obvious.

- [Auth](features/auth.md): sign-up, log in, confirming the email, password reset and the email limits.
- [Home](features/home.md): the greeting, Continue Cooking, Surprise Me and the recipe rows.
- [Recipes](features/recipes.md): the list, its filters and search, and the recipe page.
- [Editor](features/editor.md): creating and editing recipes, sections and bullets, photos, and saving.
- [Account](features/account.md): name, email and password changes, appearance, help, legal pages and deleting the account.

## Reference

- [Design](design.md): colors, fonts, shared components, and loading, empty and error states.
- [Testing](testing.md): what's tested, how to run it, and what isn't covered.
- [Decisions](decisions.md): the main choices and why they were made.
- [Cloud Functions](functions.md): `scanRecipe`, its checks and limits, and how to set it up, deploy and test it.
- [Release](release.md): what's left before TestFlight and the App Store.

## Also in the repo

- [`AGENTS.md`](../AGENTS.md): the short rule sheet for coding agents (Claude Code reads it through `CLAUDE.md`).
- [`firestore.rules`](../firestore.rules): the Firestore security rules.
- [`functions/`](../functions): the Cloud Functions, deployed with `firebase deploy --only functions`.

## Keeping these up to date

Update the docs in the same change as the behavior they describe. A few things are easy to forget:

- After changing `firestore.rules`, publish them in the Firebase console ([how](data-and-security.md#publishing-the-rules)).
- After changing `functions/`, deploy them ([how](functions.md#deploy)).
- When behavior changes, update Help's answers (`HelpTopic.all`), and the Privacy Policy if it touches data.
- When packages change, update Acknowledgments (`OpenSourceComponent.all` and `Resources/Licenses/`).
