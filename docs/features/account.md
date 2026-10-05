# Account

The third tab. The code is in `Features/Account/`.

## Sections

1. **Header:** the name's initial in a circle, the name and the email (or "Signed in as" and the email when there's no name).
2. **Profile:** Add Your Name / Change Name, Change Email, Change Password.
3. **Appearance:** System, Light or Dark.
4. **Support:** Help.
5. **Legal:** Privacy Policy, Terms of Use, Acknowledgments.
6. **Danger Zone:** Log Out, Delete Account.

The version ("Revora 1.0 (1)") sits under the last section.

## Name

Stored as Firebase Auth's `displayName`, not in Firestore, so it needs no rules. Saving an empty name removes it. Home greets people with the first word of it.

## Change email

Firebase's verify-before-update flow: the new email gets a link, and the email only changes once it's opened. Changing it without proving the new address would let an account move to an address its owner doesn't control. The old address gets Firebase's notice with an undo link.

**Opening the link logs the person out everywhere**, including this app, and they log in again with the new email:

- Firebase ends every session when the email changes, but the app only notices on its next token refresh, up to an hour later. So `AuthService.refreshUser()` forces one when the app becomes active, when Account appears, and every 10 seconds for up to 10 minutes while a change is waiting (`pendingEmail`).
- When the session ends that way, Login says "Your email is now …" and fills it in.
- If the app is quit before the link is opened, the next token refresh still logs out, but without that note.

The form checks that the new email is valid and different from the current one (ignoring case), and asks for the password, because Firebase needs a recent sign-in. The email limits apply (see [Auth](auth.md#email-limits)).

## Change password

Current password, new password and the new one again. The current one only needs filling in, since older passwords may be shorter than today's minimum. The new one needs 8 characters and must differ from the current one. The app re-authenticates first, then updates the password, and stays signed in.

## Appearance

Saved on the device under `appearance`, not in the account, because it's about this screen. It's applied once in `RootView`, so it also reaches sheets and the auth screens. The launch screen always follows the device, because the system draws it before the app runs.

## Help

`HelpTopic.all` holds the questions and answers, grouped into topics, shown as expandable rows. The answers describe how the app behaves today, so **update them when behavior changes.** `HelpTopicTests` checks every topic and answer is filled in.

There's no contact option yet. See [Release](../release.md#support-and-contact).

## Legal pages

The Privacy Policy and Terms of Use are Markdown files in `Resources/Legal/`, shown in the app by `LegalDocumentView`. They're drafts, and need to move to a website before an App Store release (see [Release](../release.md#legal-pages)).

**Acknowledgments** lists every open-source component the app links, with its licence text from `Resources/Licenses/`. When packages change, update `OpenSourceComponent.all` and the licence files. `LegalTextTests` checks every page and licence is in the bundle.

## Log out

Logs out straight away, without asking, since nothing is lost. If it fails, an alert offers to try again.

## Delete account

A page that lists what's removed (the email, and "N recipes, with their photos"), says it can't be undone, and asks for the password. The red button then asks once more.

The order matters:

1. **Re-authenticate.** Firebase only deletes an account that signed in recently, and this confirms it's really them. A wrong password shows under the field and deletes nothing.
2. **Delete every recipe's photos, then the recipes.** The recipes are read from the server, not the cache, which also fails straight away when offline, before anything is deleted. Deletes go in batches of up to 500 and are awaited, unlike other writes, because once the account is gone the rules would reject anything still waiting to sync.
3. **Delete the Firebase Auth user.** It goes last because the rules need a signed-in user to delete the recipes.

If a step fails, the error shows on the page, and trying again picks up from there. The in-memory photo cache is cleared at the end.

Unconfirmed accounts can't reach this page. Remove them in the Firebase console (Authentication → Users).
