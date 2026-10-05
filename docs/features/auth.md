# Auth

Signing up, logging in, confirming the email and resetting a password. The screens are in `Features/Auth/`. Everything that talks to Firebase is in `AuthService`.

## Screens

- **Login** is the root of `AuthFlow`. "Forgot password?" and "Create an account" push the other two screens.
- **Create Account** asks for an optional name, an email, a password and the password again.
  - Passwords need at least 8 characters (`AuthService.minimumPasswordLength`), stricter than Firebase's 6.
  - The name is optional and at most 50 characters. Home greets people with its first word.
  - If the email already has an account, the error offers **Log In Instead**, which goes back to Login with the email filled in.
- **Reset Password** sends Firebase's reset link. The email from Login is filled in.

Validation lives in small form types (`RegisterForm`, `LoginForm`, `EmailAddress`, `PersonName`) that are unit tested. Tapping empty space closes the keyboard, so the main button never stays hidden behind it.

## Not revealing who has an account

With email enumeration protection on in the Firebase console, the app never says whether an email has an account:

- A wrong password, an unknown email and an invalid credential all show one message: "That email and password don't match. Try again or reset your password." It comes with a **Reset Password** action.
- Reset Password always shows "If there's an account for …, you'll get a link". An unknown email is treated as sent.
- The email limits below count a reset to an unknown email too.

## Confirming the email

New accounts must confirm their email before the app opens. Until then `AuthService.state` is `.unverified`, and `VerifyEmailView` takes the place of the tabs. The security rules check the same thing on the server, so an unconfirmed account can't reach any recipes even outside the app.

- Registering sends the first link. If that fails, it's only logged, and the screen can send another.
- There's no "I've confirmed it" button. While the screen shows, the app checks every 5 seconds, and again whenever it becomes active. The link can be opened on another device.
- When the email is confirmed, the app forces a token refresh **before** it opens the tabs. The recipe listener would otherwise start with a token that still says unconfirmed, and the rules would reject it.
- Whether a link went out is saved per account in `UserDefaults` (`SentVerifications`). So reopening the app says "We sent a link" instead of offering a new one. Older accounts made before confirming was required see **Send Link** instead.
- **Log Out** is there in case someone signed up with the wrong address.

## Email limits

Firebase's free plan allows about 150 password resets a day for the whole project, and 1,000 each of verification and email-change emails. A few quick taps, or one person on purpose, could use up the day's resets for everyone. So the app holds back before asking Firebase to send one (`EmailRateLimit`):

| Kind | Same address | Per device, per hour |
|---|---|---|
| Password reset | 60 s apart | 3 |
| Confirmation link | 60 s apart | 5 |
| Email change | 60 s apart | 5 |

- While a limit applies, the button is disabled, and `EmailWaitNote` says when another link can be sent, with a live countdown. It clears itself when the time is up.
- Sends are kept in `UserDefaults` for an hour, with addresses as SHA-256 hashes. Sends dated in the future (the clock was turned back) are ignored.
- `AuthService` checks the limit itself too, and throws `.tooManyRequests` if a screen didn't.

They're a courtesy in the app, not a security boundary: Firebase doesn't know about them. App Check makes Firebase accept requests only from the real app (see [Release](../release.md#app-check)).

## Wrong passwords

There's no backoff in the app. Firebase locks out repeated wrong passwords on its server, and that can't be skipped. Its `tooManyRequests` error shows as "Too many attempts. Wait a moment and try again." That covers log in and every re-authentication (changing the email or password, deleting the account).

## Timeouts and errors

Every awaited Firebase Auth call has a 15-second timeout, so a stalled connection says "This is taking too long" instead of spinning for a minute. `AuthError` maps Firebase's error codes to friendly messages in one place. Re-authentication maps a wrong password to "That password isn't right" instead of the log-in message.
