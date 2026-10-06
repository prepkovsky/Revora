import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { blockedCategories } from "./moderation.js";
import { moderate, readRecipe } from "./openai.js";
import { dataURL, decodePhoto } from "./photo.js";
import { scannedRecipe } from "./recipe.js";
import { countedScan, dailyScanLimit, nextUTCMidnight, readUsage, refundedScan } from "./usage.js";

initializeApp();

const openAIKey = defineSecret("OPENAI_API_KEY");

/**
 * Reads the recipe in a photo, for the app to open in the editor. Nothing is saved
 * except the user's scan count, and the photo goes to OpenAI and nowhere else.
 *
 * Request `{ image }`: a base64 JPEG. Response `{ recipe }`: see `ScannedRecipe`.
 */
export const scanRecipe = onCall(
  { secrets: [openAIKey], timeoutSeconds: 90, memory: "512MiB", maxInstances: 10 },
  async (request) => {
    const auth = request.auth;
    if (!auth) throw new HttpsError("unauthenticated", "Log in to scan recipes.");
    // Like the security rules, so only accounts that can save recipes can scan them.
    if (auth.token.email_verified !== true) {
      throw new HttpsError("permission-denied", "Confirm your email to scan recipes.");
    }

    const photo = decodePhoto((request.data as { image?: unknown } | null)?.image);
    if (!photo) throw new HttpsError("invalid-argument", "This photo couldn't be read.");

    const day = await countScan(auth.uid, new Date());
    // Only failures on OpenAI's side give the scan back. A blocked photo or a photo
    // without a recipe still cost a request, so retrying them uses up the limit.
    let givesScanBack = true;
    try {
      const imageURL = dataURL(photo);
      const blocked = blockedCategories(await moderate(imageURL, openAIKey.value()));
      if (blocked.length > 0) {
        givesScanBack = false;
        logger.warn("Scan photo blocked by moderation", { uid: auth.uid, categories: blocked });
        throw new HttpsError("failed-precondition", "This photo can't be scanned. Try a photo of a recipe.");
      }

      const recipe = scannedRecipe(await readRecipe(imageURL, auth.uid, openAIKey.value()));
      givesScanBack = false;
      if (!recipe) throw new HttpsError("not-found", "There's no recipe in this photo.");
      return { recipe };
    } catch (error) {
      if (givesScanBack) {
        await giveScanBack(auth.uid, day).catch((refundError: unknown) => {
          logger.error("Couldn't give a scan back", { uid: auth.uid, error: String(refundError) });
        });
      }
      if (error instanceof HttpsError) throw error;
      logger.error("Scan failed", { uid: auth.uid, error: String(error) });
      throw new HttpsError("unavailable", "The scan didn't work. Try again in a moment.");
    }
  },
);

/** Counts a scan against today's limit and returns the day it was counted for. */
async function countScan(uid: string, now: Date): Promise<string> {
  const db = getFirestore();
  const ref = db.collection("scanUsage").doc(uid);
  return db.runTransaction(async (transaction) => {
    const usage = countedScan(readUsage((await transaction.get(ref)).data()), now);
    const resetsAt = nextUTCMidnight(now);
    if (!usage) {
      throw new HttpsError("resource-exhausted", `You can scan ${dailyScanLimit} recipes a day.`, {
        resetsAt: resetsAt.toISOString(),
      });
    }
    // The rules don't match scanUsage, so only this function can read or change the count.
    transaction.set(ref, { ...usage, expiresAt: Timestamp.fromDate(resetsAt) });
    return usage.day;
  });
}

async function giveScanBack(uid: string, day: string): Promise<void> {
  const db = getFirestore();
  const ref = db.collection("scanUsage").doc(uid);
  await db.runTransaction(async (transaction) => {
    const usage = refundedScan(readUsage((await transaction.get(ref)).data()), day);
    if (usage) transaction.update(ref, { count: usage.count });
  });
}
