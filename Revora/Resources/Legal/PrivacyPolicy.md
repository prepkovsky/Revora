*Last updated: October 6, 2026*

Revora is a place to keep your own recipes. This policy explains what the app stores, why, and what you can do about it.

## What Revora stores

- **Your account:** your email address, your name if you add one, and your password. The password is handled by Firebase Authentication, which stores it in a form that can't be read back, so nobody can see it.
- **Your recipes:** titles, ingredients, steps, meal types, which recipes are favorites, and when you created, edited and last opened each one.
- **Cover photos** you add to recipes. They're made smaller on your device first, and their metadata, such as where a photo was taken, is removed before upload.
- **How many recipes you've scanned today**, so the daily scan limit works. It's deleted once the day is over.
- **Technical information** that Firebase needs to run the service and keep it secure, such as your IP address and the app version.

## What Revora doesn't do

- No ads.
- No analytics or tracking, and nothing that follows you across other apps or websites.
- Your data is never sold or shared for marketing.

## How your data is used

Only to run the app: to sign you in, to save your recipes and photos and sync them to your devices, to read the recipes in photos you scan, and to send the emails you ask for, like password resets and confirming a new email address.

## Scanning recipes

When you scan a recipe, the photo is made smaller on your device, its metadata is removed, and it's sent to OpenAI, which reads the recipe and sends it back to the app. You then check it and choose whether to save it.

- Revora doesn't keep the photo, and it isn't added to your recipe.
- OpenAI, L.L.C. processes the photo on Revora's behalf. It doesn't use it to train its models, and may keep it for up to 30 days to detect misuse before deleting it. Images it flags as possible child sexual abuse material can be kept longer for review.
- OpenAI first checks the photo with its moderation service, so photos that are clearly harmful can't be scanned.
- Your name and email aren't sent. OpenAI only receives a code made from your account ID, which can't be turned back into it, so misuse can be traced to an account without telling OpenAI who you are.

## Where it's stored

Your account, recipes and photos are stored with Google Firebase (Firebase Authentication and Cloud Firestore), a service run by Google LLC that processes the data on Revora's behalf. Scans pass through a Firebase Cloud Function in the United States on their way to OpenAI. It may be stored on servers outside your country. Data is encrypted on its way to Firebase and while it's stored there.

Revora also keeps a copy of your recipes on your device so it works offline. It saves your appearance setting there too, and when it last sent you an email link, so it can wait a moment before sending another. Deleting the app removes them.

## How long it's kept

Your data is kept for as long as you have an account. Deleting a recipe removes it and its photo. Deleting your account removes the account and all of its recipes and photos. Your daily scan count is deleted after the day it's for, and scanned photos aren't kept by Revora at all.

## Your choices and rights

- You can see and edit everything Revora stores about your recipes in the app.
- You can delete any recipe, or your whole account, in the app at any time.
- You can ask for a copy of your data, or ask any question about it, by contacting the developer.

## Children

Revora isn't meant for children under 13, and doesn't knowingly collect their data.

## Changes to this policy

If this policy changes, this page will be updated and the date at the top will change.

## Contact

If you have a question about this policy or your data, contact the developer.
