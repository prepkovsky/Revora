# Getting started

How to build and run Revora from a fresh clone.

## Requirements

- A Mac with Xcode 27
- An iOS or iPadOS 18 (or later) simulator or device
- A Firebase project. The free Spark plan is enough.

Firebase comes in through Swift Package Manager (FirebaseAuth, FirebaseFirestore and FirebaseFunctions from `firebase-ios-sdk`). There are no other dependencies.

## Set up Firebase

The app talks to one Firebase project, described by `Revora/GoogleService-Info.plist`. That file is gitignored, so a fresh clone won't build until you add it. Keep a copy of it somewhere outside the repo.

1. In the [Firebase console](https://console.firebase.google.com), create a project, or open the existing one.
2. **Authentication → Sign-in method:** turn on **Email/Password**.
3. **Authentication → Settings → User actions:** make sure **Email enumeration protection** is on, so sign-in and password reset don't reveal which emails have accounts.
4. **Firestore Database:** create a database.
5. **Firestore Database → Rules:** paste in `firestore.rules` from the repo root and publish it. See [Data and security](data-and-security.md#security-rules).
6. **Project settings → Your apps:** register an iOS app with the target's bundle ID (`dev.patrikrepkovsky.revora`; change it in Xcode under Signing & Capabilities first if you use your own project). Download its `GoogleService-Info.plist` and put it at `Revora/GoogleService-Info.plist`.
7. Optional: in Google Cloud Console → APIs & Services → Credentials, restrict the iOS API key to the bundle ID.

Never commit `GoogleService-Info.plist`, and don't take it out of `.gitignore`. It holds no real secret (the security rules protect the data), but keeping it out of the repo stops key scanners from flagging it.

## Run in Xcode

1. Open `Revora.xcodeproj`. Xcode resolves the Firebase packages on the first open.
2. Pick the **Revora** scheme and a simulator or device.
3. Build and run.

Running on a simulator needs a signed build. Pick your own team under Signing & Capabilities if the project's team isn't yours.

A new account has to confirm its email before the app opens. The link comes from Firebase, so use an address you can read.

## Build from the command line

```sh
xcodebuild -project Revora.xcodeproj -scheme Revora -sdk iphonesimulator \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

`CODE_SIGNING_ALLOWED=NO` is fine for checking that the app compiles. To install the build on a simulator, leave it out so the app is signed.

## Run the tests

```sh
xcodebuild -project Revora.xcodeproj -scheme Revora \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Any iPhone simulator on iOS 18 or later works. The tests use Swift Testing and never call Firebase. See [Testing](testing.md).

If Xcode is open and resolving packages at the same time, add `-clonedSourcePackagesDirPath <tmp dir>` to avoid cache conflicts.

## Next

- [Architecture](architecture.md): how the code is laid out.
- [Data and security](data-and-security.md): what's stored in Firestore and who can reach it.
