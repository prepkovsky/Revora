import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { categoryScores, moderationRequest, OpenAIError, outputJSON, recipeRequest, safetyIdentifier } from "./openai.js";

describe("safetyIdentifier", () => {
  test("is a SHA-256 hash of the user ID, never the ID itself", () => {
    const identifier = safetyIdentifier("user-123");
    assert.match(identifier, /^[0-9a-f]{64}$/);
    assert.ok(!identifier.includes("user-123"));
    assert.equal(identifier, safetyIdentifier("user-123"));
    assert.notEqual(identifier, safetyIdentifier("user-124"));
  });
});

describe("requests", () => {
  test("moderation sends only the photo", () => {
    assert.deepEqual(moderationRequest("data:image/jpeg;base64,AAAA"), {
      model: "omni-moderation-latest",
      input: [{ type: "image_url", image_url: { url: "data:image/jpeg;base64,AAAA" } }],
    });
  });

  test("the recipe request isn't stored and names the user only by hash", () => {
    const request = recipeRequest("data:image/jpeg;base64,AAAA", safetyIdentifier("user-123"));
    assert.equal(request.store, false);
    assert.equal(request.safety_identifier, safetyIdentifier("user-123"));
    assert.equal(request.text.format.strict, true);
    assert.deepEqual(request.input[0]?.content, [
      { type: "input_image", image_url: "data:image/jpeg;base64,AAAA", detail: "original" },
    ]);
  });
});

describe("categoryScores", () => {
  test("reads the photo's scores", () => {
    const response = { results: [{ flagged: true, category_scores: { sexual: 0.1 } }] };
    assert.deepEqual(categoryScores(response), { sexual: 0.1 });
  });

  test("throws without scores", () => {
    for (const response of [null, {}, { results: [] }, { results: [{ flagged: false }] }]) {
      assert.throws(() => categoryScores(response), OpenAIError);
    }
  });
});

describe("outputJSON", () => {
  const recipe = { isRecipe: true, title: "Soup" };

  function response(content: unknown[], status = "completed") {
    return {
      status,
      output: [
        { type: "reasoning", summary: [] },
        { type: "message", role: "assistant", content },
      ],
    };
  }

  test("reads the structured output after reasoning", () => {
    const reply = response([{ type: "output_text", text: JSON.stringify(recipe), annotations: [] }]);
    assert.deepEqual(outputJSON(reply), recipe);
  });

  test("throws on a cut-off answer", () => {
    const reply = response([{ type: "output_text", text: '{"isRecipe": true, "ti' }], "incomplete");
    assert.throws(() => outputJSON(reply), OpenAIError);
  });

  test("throws on a refusal", () => {
    assert.throws(() => outputJSON(response([{ type: "refusal", refusal: "I can't help with that." }])), /refused/);
  });

  test("throws on text that isn't JSON", () => {
    assert.throws(() => outputJSON(response([{ type: "output_text", text: "Here's the recipe:" }])), OpenAIError);
  });

  test("throws without a message", () => {
    for (const reply of [null, {}, { status: "completed" }, { status: "completed", output: [] }, response([])]) {
      assert.throws(() => outputJSON(reply), OpenAIError);
    }
  });
});
