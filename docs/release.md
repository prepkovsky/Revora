# Release

What's left before Revora can go on TestFlight and the App Store. The app itself is ready to upload: it has a privacy manifest and declares its encryption use. Most of what remains needs a **paid Apple Developer account**, which TestFlight, the App Store and App Attest all require.

## Checklist

- [ ] Paid Apple Developer account, and the app's bundle ID registered under it
- [ ] [App Check](#app-check) with App Attest, enforced on Firestore and Authentication, **before any build goes to other people**
- [ ] [Legal pages](#legal-pages) on a website, with the developer's name and a contact address
- [ ] [Support URL and a Contact row](#support-and-contact)
- [ ] [App Privacy label](#privacy) in App Store Connect, matching the privacy manifest
- [ ] [Firebase console](#firebase-console) settings checked
- [ ] Help answers still match the app (`HelpTopic.all`)
- [ ] Version and build number set (target → General)
- [ ] App Store screenshots, description and keywords
- [ ] A last pass by hand (see [Testing](testing.md#what-isnt-covered)), on a real device, including the camera

## App Check

Without App Check, Firebase accepts requests from any client that has the app's Firebase configuration, not just the app, so the app's own limits (like the email limits) aren't enforced on the server. With the **App Attest** provider, Firebase only accepts requests from the real app on a real Apple device.

**Turn it on before any build goes to other people**, on TestFlight or the App Store. Anyone with a copy of the app can read its Firebase configuration out of it.

1. Add the `FirebaseAppCheck` product from the `firebase-ios-sdk` package that's already in the project. It's a new Firebase product, so agree it first.
2. Set up App Attest in the app, before `FirebaseApp.configure()`. The simulator can't use App Attest, so Debug builds use the debug provider, with a debug token registered in the Firebase console.
3. In the Firebase console, register the app for App Attest, then watch the App Check metrics for a while to see that real traffic passes.
4. Enforce it on **Cloud Firestore**, then on **Authentication** (still in preview, and it covers sign-up, sign-in and reset emails). Check whether Authentication enforcement needs the Identity Platform upgrade.

App Attest costs nothing, but needs the paid account. If that's ever not enough, the next step is the Blaze plan with a `beforeEmailSent` blocking function, which can limit emails per address or IP and raises the daily reset emails from 150 to 10,000.

The Firebase configuration isn't in this repository, so the code alone gives no access to the project. Until a build goes to other people, it only exists in the gitignored `GoogleService-Info.plist` and in builds on your own devices. See [Known gaps](data-and-security.md#known-gaps).

## Legal pages

App Store Connect needs a privacy policy URL. The Privacy Policy and Terms of Use are in the app for now (`Resources/Legal/`), as drafts.

1. Add the developer's name and a contact address. Both texts say "contact the developer" without one for now.
2. Have the texts reviewed. They aren't legal advice.
3. Publish them on a website. The Markdown files can be its starting point.
4. Make the Privacy Policy and Terms rows in Account open those URLs instead of the bundled pages (`LegalPage`), so the texts can change without an app update.

Acknowledgments stays in the app.

## Support and contact

- App Store Connect needs a **support URL**.
- Add a **Contact** row to Account → Support, next to Help: an email address or a form on the website. It was left out until there's a support address.
- Consider a Help answer that points to it.

## Privacy

`Revora/PrivacyInfo.xcprivacy` declares:

- **No tracking**, and no tracking domains.
- **Data collected**, all linked to the user and only for app functionality: email address, name, photos, and other user content (the recipes).
- **Required-reason API:** `UserDefaults`, reason `CA92.1` (appearance, sent confirmations, email limits).

Xcode combines it with the Firebase packages' own manifests into the app's privacy report. Fill in the **App Privacy** label in App Store Connect from that report. Firebase's manifests add:

- **User ID**, linked, for app functionality (FirebaseAuth).
- **Other Diagnostic Data**, not linked, for analytics (FirebaseAuth and FirebaseFirestore send usage reports about the SDK itself).

The Privacy Policy currently says "No analytics or tracking". **Reconcile that wording with Firebase's diagnostics declaration before publishing.**

`Info.plist` sets `ITSAppUsesNonExemptEncryption` to `NO`: the app only uses encryption for HTTPS to Firebase and for hashing, which are exempt. Confirm that when uploading.

## Firebase console

- **Email enumeration protection** on (Authentication → Settings → User actions).
- **API key** restricted to the bundle ID (Google Cloud Console → APIs & Services → Credentials).
- **Email templates** (Authentication → Templates): verification, password reset and email change still use Firebase's default wording and sender name. Customize them if wanted.
- **Security rules** published and matching `firestore.rules`.
- **Free plan limits** (see [Data and security](data-and-security.md#free-plan-limits)). Watch usage once real people sign up, and move to Blaze if the daily email or Firestore allowances get close.
