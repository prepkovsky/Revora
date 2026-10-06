/**
 * The scores at which a photo is turned away, for the categories OpenAI's moderation model
 * scores images on. Its own `flagged` answer isn't used: it's tuned for user posts, and
 * cookbook pages often show raw meat or a whole fish, which must still scan. The point is
 * keeping clearly abusive photos away from the recipe model, so the OpenAI account stays in
 * good standing.
 */
export const blockThresholds: Readonly<Record<string, number>> = {
  sexual: 0.8,
  "self-harm": 0.8,
  "self-harm/intent": 0.8,
  "self-harm/instructions": 0.8,
  violence: 0.9,
  "violence/graphic": 0.9,
};

/** The categories a photo scored at or above the threshold for. Empty means it can be scanned. */
export function blockedCategories(scores: Readonly<Record<string, unknown>>): string[] {
  return Object.entries(blockThresholds)
    .filter(([category, threshold]) => {
      const score = scores[category];
      return typeof score === "number" && score >= threshold;
    })
    .map(([category]) => category);
}
