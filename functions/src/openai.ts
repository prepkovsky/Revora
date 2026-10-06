import { createHash } from "node:crypto";
import { recipeInstructions, recipeSchema } from "./recipe.js";

/** Vision-capable and the cheapest current model. The instructions and schema don't depend on it. */
export const recipeModel = "gpt-6-luna";
export const moderationModel = "omni-moderation-latest";

const apiURL = "https://api.openai.com/v1";

/** OpenAI couldn't be reached, or didn't give a usable answer. */
export class OpenAIError extends Error {}

/** Lets OpenAI tie abuse to one user instead of the whole account. Hashed, so it never learns who. */
export function safetyIdentifier(uid: string): string {
  return createHash("sha256").update(uid).digest("hex");
}

export function moderationRequest(imageURL: string) {
  return {
    model: moderationModel,
    input: [{ type: "image_url", image_url: { url: imageURL } }],
  };
}

export function recipeRequest(imageURL: string, safetyIdentifier: string) {
  return {
    model: recipeModel,
    instructions: recipeInstructions,
    // "original" keeps the photo's full size, which small print needs.
    input: [{ role: "user", content: [{ type: "input_image", image_url: imageURL, detail: "original" }] }],
    text: { format: { type: "json_schema", name: "recipe", strict: true, schema: recipeSchema } },
    reasoning: { effort: "low" },
    max_output_tokens: 8000,
    // Not kept for OpenAI's dashboard or later requests.
    store: false,
    safety_identifier: safetyIdentifier,
  };
}

/** The scores per category for the one photo in a moderation request. */
export function categoryScores(response: unknown): Record<string, unknown> {
  const scores = (response as { results?: { category_scores?: unknown }[] } | null)?.results?.[0]?.category_scores;
  if (typeof scores !== "object" || scores === null) throw new OpenAIError("Moderation reply has no scores");
  return scores as Record<string, unknown>;
}

/** The structured output in a Responses API reply. A refusal or a cut-off answer has none. */
export function outputJSON(response: unknown): unknown {
  const reply = response as { status?: unknown; output?: unknown } | null;
  if (reply?.status !== "completed") throw new OpenAIError(`Recipe reply is ${String(reply?.status)}`);

  const message = Array.isArray(reply.output)
    ? reply.output.find((item) => item?.type === "message")
    : undefined;
  const content: unknown[] = Array.isArray(message?.content) ? message.content : [];
  const text = content.find((part) => (part as { type?: unknown })?.type === "output_text") as
    | { text?: unknown }
    | undefined;
  if (typeof text?.text !== "string") {
    const refused = content.some((part) => (part as { type?: unknown })?.type === "refusal");
    throw new OpenAIError(refused ? "Recipe model refused" : "Recipe reply has no text");
  }

  try {
    return JSON.parse(text.text);
  } catch {
    throw new OpenAIError("Recipe reply isn't JSON");
  }
}

export async function moderate(imageURL: string, apiKey: string): Promise<Record<string, unknown>> {
  return categoryScores(await post("/moderations", moderationRequest(imageURL), apiKey, 20_000));
}

/** Leaves time for moderation before it within the function's 90 seconds. */
export async function readRecipe(imageURL: string, uid: string, apiKey: string): Promise<unknown> {
  return outputJSON(await post("/responses", recipeRequest(imageURL, safetyIdentifier(uid)), apiKey, 60_000));
}

async function post(path: string, body: object, apiKey: string, timeoutMs: number): Promise<unknown> {
  try {
    const response = await fetch(apiURL + path, {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeoutMs),
    });
    if (!response.ok) {
      // OpenAI's error says what went wrong, which is what the logs need.
      const detail = await response.text().catch(() => "");
      throw new OpenAIError(`${path} returned ${response.status}: ${detail.slice(0, 500)}`);
    }
    return await response.json();
  } catch (error) {
    if (error instanceof OpenAIError) throw error;
    throw new OpenAIError(`${path} failed: ${String(error)}`);
  }
}
