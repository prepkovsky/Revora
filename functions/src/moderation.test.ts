import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { blockedCategories, blockThresholds } from "./moderation.js";

describe("blockedCategories", () => {
  test("lets a cookbook page with raw meat through", () => {
    const scores = { sexual: 0.0004, violence: 0.12, "violence/graphic": 0.41, "self-harm": 0.001 };
    assert.deepEqual(blockedCategories(scores), []);
  });

  test("blocks a photo at or above a threshold", () => {
    assert.deepEqual(blockedCategories({ sexual: 0.95 }), ["sexual"]);
    assert.deepEqual(blockedCategories({ violence: blockThresholds.violence }), ["violence"]);
  });

  test("lists every category over its threshold", () => {
    const scores = { "self-harm": 0.9, "self-harm/intent": 0.85, violence: 0.95, sexual: 0.1 };
    assert.deepEqual(blockedCategories(scores), ["self-harm", "self-harm/intent", "violence"]);
  });

  test("ignores categories that aren't scored on images", () => {
    assert.deepEqual(blockedCategories({ harassment: 0.99, hate: 0.99, illicit: 0.99 }), []);
  });

  test("ignores missing and invalid scores", () => {
    assert.deepEqual(blockedCategories({}), []);
    assert.deepEqual(blockedCategories({ sexual: "0.99", violence: null }), []);
  });
});
