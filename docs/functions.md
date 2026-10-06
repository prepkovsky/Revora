# Cloud Functions

Revora has one Cloud Function, `scanRecipe`, which reads the recipe in a photo. It lives in [`functions/`](../functions), in TypeScript. The OpenAI key it uses only exists as a Firebase secret, never in the app or the repo, because anything bundled into an iOS app can be read out of it.

Functions need the **Blaze** plan.

## scanRecipe

A callable function (`onCall`), so Firebase checks the caller's ID token before it runs. It runs in the default region, `us-central1`.

**Request:** `{ image }`, a base64 JPEG of at most 2 MiB.

**Response:** `{ recipe }`, a new recipe in the shape the app saves (see [Firestore layout](data-and-security.md#firestore-layout)), without an ID, dates or photo:

```
title, ingredientSections [{ title?, items [{ name, quantity }] }],
stepSections [{ title?, items [{ text, bullets [String] }] }], mealTypes [String]
```

The function saves nothing except the user's scan count. The photo goes to OpenAI and nowhere else, and the app opens the result in the editor for the user to check and save.

### What it checks

In this order. Each failure is an `HttpsError` with this code:

| Check | Code | Scan counted |
|---|---|---|
| Signed in | `unauthenticated` | No |
| Email confirmed, like the security rules | `permission-denied` | No |
| The photo is a JPEG within the size limit | `invalid-argument` | No |
| Under today's limit | `resource-exhausted`, with `details.resetsAt` (ISO date) | No |
| The photo passes moderation | `failed-precondition` | Yes |
| OpenAI answers | `unavailable` | No, it's given back |
| There's a recipe in the photo | `not-found` | Yes |

A failure on OpenAI's side (an error, a timeout, a refusal, a cut-off or malformed answer) gives the scan back. A blocked photo or a photo without a recipe still cost a request, so it counts.

The messages are only a fallback: callers should show their own friendly message for each code.

### Daily limit

20 scans per user per UTC day, counted in `scanUsage/{uid}`:

```
scanUsage/{uid}   day: "2026-10-06", count: Int, expiresAt: Timestamp (the next UTC midnight)
```

The count is read and updated in a transaction. The security rules don't match `scanUsage`, so the app can't read or change it, only the function can. A TTL policy on `expiresAt` deletes old counts, including those of deleted accounts.

### Moderation

Before the recipe model, the photo goes to OpenAI's Moderation API (`omni-moderation-latest`, free). It protects the OpenAI account: sending it clearly abusive images could get the whole account restricted.

It only turns away clearly harmful photos. Cookbook pages often show raw meat or a whole fish, so OpenAI's own `flagged` answer isn't used. Instead, `blockThresholds` in `moderation.ts` sets a score per category it rates images on: 0.8 for sexual and self-harm, 0.9 for violence. A blocked photo gets a neutral message, and the log records which categories, never the photo. If moderation itself fails, the scan fails as `unavailable`.

### Reading the recipe

One request to OpenAI's Responses API with plain `fetch` (no OpenAI SDK):

- **Model:** `recipeModel` in `openai.ts` (`gpt-6-luna`). Change it there when a better or cheaper one comes out.
- **Structured output** in strict mode (`recipeSchema` in `recipe.ts`), with an `isRecipe` flag so the model can say there's no recipe instead of inventing one.
- **Instructions** (`recipeInstructions`): copy the recipe as written, in its own language, without translating or adding anything; sections only where the recipe has headings.
- **`detail: "original"`**, so small print isn't scaled down.
- **`store: false`**, so OpenAI doesn't keep the response for later use.
- **`safety_identifier`:** a SHA-256 hash of the user ID, so OpenAI can tie abuse to one user instead of the whole account without learning who it is.

The answer is cleaned up like the editor does when saving: text is trimmed and kept to one line, blank items, bullets and empty sections are dropped, step numbers and bullet characters copied from the page are removed, and meals are put in `MealType`'s order. A section without a title that follows a named one joins it, the way the editor groups rows.

### Limits

| | |
|---|---|
| Photo | 2 MiB, JPEG only |
| Moderation | 20 s |
| Recipe model | 60 s, 8,000 output tokens |
| Function | 90 s, 512 MiB, at most 10 instances |

## Setup

Once per Firebase project:

1. Move the project to **Blaze**. In Google Cloud console → **Billing → Budgets & alerts**, add a budget alert. In the OpenAI dashboard, set a monthly budget limit.
2. Install the Firebase CLI and sign in:
   ```sh
   npm install -g firebase-tools
   firebase login
   ```
3. From the repo root, pick the project. This writes `.firebaserc`, which is gitignored because it names the project, like `GoogleService-Info.plist`.
   ```sh
   firebase use --add
   ```
4. Create an OpenAI API key and store it as a secret. Paste it when asked; it never goes in a file.
   ```sh
   firebase functions:secrets:set OPENAI_API_KEY
   ```
5. In Google Cloud console → **Firestore → Time-to-live**, create a policy for collection group `scanUsage`, field `expiresAt`.

Don't put the key in `functions/.env`: those values are deployed as plain environment settings. For the local emulator, put it in `functions/.secret.local`, which is gitignored.

## Deploy

```sh
firebase deploy --only functions
```

`firebase.json` only configures functions, so this never touches the security rules, which are still [published by hand](data-and-security.md#publishing-the-rules). Before uploading, it builds and runs the tests (`npm test` in `functions/`), and stops if they fail.

After every change in `functions/`, deploy it. Logs are in the Firebase console → **Functions → Logs**, or:

```sh
firebase functions:log --only scanRecipe
```

## Tests

```sh
npm --prefix functions test
```

This compiles the TypeScript and runs the tests with Node's built-in test runner. They cover the logic that doesn't need Firebase or OpenAI: photo checks, the moderation decision, the safety identifier, the OpenAI requests and reading their replies, cleaning the recipe, the daily count, and that the schema's meals match the app's `MealType`. The callable itself, the transaction and the real OpenAI calls are checked by hand after deploying.

Run `npm install --prefix functions` first after a fresh clone.
