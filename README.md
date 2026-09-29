# Revora

A simple recipe app for iPhone and iPad. Sign up with email and password, save your own recipes (title, ingredients and steps), and mark your favorites.

> **Status:** early development. The app shell, navigation, sign-up, log in and password reset are in place; recipe storage is next.

## Requirements

- Xcode 27
- iOS / iPadOS 18 or later
- A Firebase project with **Authentication** (Email/Password) and **Cloud Firestore** enabled

## Setup

1. Clone the repo and open `Revora.xcodeproj`. Xcode resolves the Firebase packages (FirebaseAuth and FirebaseFirestore) through Swift Package Manager.
2. In the Firebase console, register an iOS app with the project's bundle ID and download its `GoogleService-Info.plist`.
3. Put the file at `Revora/GoogleService-Info.plist`. It's gitignored on purpose, so don't commit it.
4. Build and run the **Revora** scheme.

The app won't build without `GoogleService-Info.plist`.

## Building and testing

Build from the command line:

```sh
xcodebuild -project Revora.xcodeproj -scheme Revora -sdk iphonesimulator \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Run the unit tests (any iPhone simulator on iOS 18 or later works):

```sh
xcodebuild -project Revora.xcodeproj -scheme Revora \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The unit tests use Swift Testing and never call Firebase.

## Project structure

```
Revora/
├── App/            App entry point, root view and tab bar
├── Services/       Firebase wrappers (auth, recipe storage)
├── Models/         Recipe data types
├── Features/       One folder per screen area: Auth, Home, Recipes, Editor, Settings
└── Components/     Shared reusable views
RevoraTests/        Unit tests
```

Some folders appear only once their first files are added.

Built with SwiftUI in Swift 6 language mode. Recipes will be stored in Firestore under `users/{uid}/recipes`, with security rules that let users read and write only their own data.
