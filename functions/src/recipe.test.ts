import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, test } from "node:test";
import { MalformedReplyError, mealTypes, recipeSchema, scannedRecipe } from "./recipe.js";

function reply(overrides: Record<string, unknown> = {}) {
  return {
    isRecipe: true,
    title: "Pancakes",
    ingredientSections: [{ title: null, items: [{ quantity: "200 g", name: "flour" }] }],
    stepSections: [{ title: null, items: [{ text: "Mix everything.", bullets: [] }] }],
    mealTypes: ["breakfast"],
    ...overrides,
  };
}

describe("scannedRecipe", () => {
  test("returns the recipe in the app's shape", () => {
    assert.deepEqual(scannedRecipe(reply()), {
      title: "Pancakes",
      ingredientSections: [{ items: [{ name: "flour", quantity: "200 g" }] }],
      stepSections: [{ items: [{ text: "Mix everything.", bullets: [] }] }],
      mealTypes: ["breakfast"],
    });
  });

  test("returns nothing when there's no recipe", () => {
    assert.equal(scannedRecipe(reply({ isRecipe: false })), null);
    assert.equal(scannedRecipe(reply({ ingredientSections: [], stepSections: [] })), null);
    assert.equal(
      scannedRecipe(reply({
        ingredientSections: [{ title: "Dough", items: [{ quantity: " ", name: "" }] }],
        stepSections: [{ title: null, items: [{ text: "", bullets: [" "] }] }],
      })),
      null,
    );
  });

  test("keeps a recipe with only ingredients or only steps", () => {
    assert.equal(scannedRecipe(reply({ stepSections: [] }))?.ingredientSections.length, 1);
    assert.equal(scannedRecipe(reply({ ingredientSections: [] }))?.stepSections.length, 1);
  });

  test("trims text and joins wrapped lines", () => {
    const recipe = scannedRecipe(reply({
      title: "  Apple\npie ",
      ingredientSections: [{ title: " For the\n crust ", items: [{ quantity: " 2 ", name: "eggs,\nbeaten  " }] }],
      stepSections: [{ title: null, items: [{ text: "Bake  until\r\ngolden.", bullets: ["  apples\t"] }] }],
    }));
    assert.equal(recipe?.title, "Apple pie");
    assert.deepEqual(recipe?.ingredientSections, [{ title: "For the crust", items: [{ name: "eggs, beaten", quantity: "2" }] }]);
    assert.deepEqual(recipe?.stepSections, [{ items: [{ text: "Bake until golden.", bullets: ["apples"] }] }]);
  });

  test("keeps an ingredient with only a quantity or only a name", () => {
    const recipe = scannedRecipe(reply({
      ingredientSections: [{ title: null, items: [{ quantity: "", name: "salt" }, { quantity: "2", name: "" }] }],
    }));
    assert.deepEqual(recipe?.ingredientSections[0]?.items, [{ name: "salt", quantity: "" }, { name: "", quantity: "2" }]);
  });

  test("drops blank items, bullets and empty sections", () => {
    const recipe = scannedRecipe(reply({
      ingredientSections: [
        { title: "Empty", items: [] },
        { title: "Sauce", items: [{ quantity: "", name: " " }, { quantity: "1", name: "lemon" }] },
      ],
      stepSections: [
        { title: null, items: [{ text: " ", bullets: [] }, { text: "", bullets: ["", "salt"] }] },
        { title: "Blank", items: [{ text: "", bullets: [] }] },
      ],
    }));
    assert.deepEqual(recipe?.ingredientSections, [{ title: "Sauce", items: [{ name: "lemon", quantity: "1" }] }]);
    assert.deepEqual(recipe?.stepSections, [{ items: [{ text: "", bullets: ["salt"] }] }]);
  });

  test("joins a section without a title to the one above, like the editor", () => {
    const recipe = scannedRecipe(reply({
      ingredientSections: [
        { title: null, items: [{ quantity: "", name: "a" }] },
        { title: "Filling", items: [{ quantity: "", name: "b" }] },
        { title: "  ", items: [{ quantity: "", name: "c" }] },
        { title: null, items: [{ quantity: "", name: "d" }] },
      ],
    }));
    assert.deepEqual(recipe?.ingredientSections.map((section) => [section.title, section.items.map((item) => item.name)]), [
      [undefined, ["a"]],
      ["Filling", ["b", "c", "d"]],
    ]);
  });

  test("removes step numbers and bullet characters copied from the page", () => {
    const recipe = scannedRecipe(reply({
      stepSections: [{
        title: null,
        items: [
          { text: "1. Preheat the oven.", bullets: ["• butter", "- sugar", "* flour"] },
          { text: "12) Bake.", bullets: [] },
          { text: "2 eggs go in first.", bullets: [] },
          { text: "1.5 cups of milk go in next.", bullets: [] },
        ],
      }],
    }));
    assert.deepEqual(recipe?.stepSections[0]?.items, [
      { text: "Preheat the oven.", bullets: ["butter", "sugar", "flour"] },
      { text: "Bake.", bullets: [] },
      { text: "2 eggs go in first.", bullets: [] },
      { text: "1.5 cups of milk go in next.", bullets: [] },
    ]);
  });

  test("puts meals in the app's order without repeats or unknown ones", () => {
    const recipe = scannedRecipe(reply({ mealTypes: ["dessert", "brunch", "breakfast", "dessert"] }));
    assert.deepEqual(recipe?.mealTypes, ["breakfast", "dessert"]);
  });

  test("throws on a reply that doesn't match the schema", () => {
    for (const malformed of [
      null,
      [],
      "recipe",
      { isRecipe: "yes" },
      reply({ title: 1 }),
      reply({ ingredientSections: {} }),
      reply({ ingredientSections: [{ title: 2, items: [] }] }),
      reply({ stepSections: [{ title: null, items: [{ text: "Mix", bullets: "salt" }] }] }),
      reply({ mealTypes: undefined }),
    ]) {
      assert.throws(() => scannedRecipe(malformed), MalformedReplyError);
    }
  });
});

describe("recipeSchema", () => {
  test("lists the same meals as the app's MealType", () => {
    const swift = readFileSync(new URL("../../Revora/Models/MealType.swift", import.meta.url), "utf8");
    const cases = [...swift.matchAll(/^\s*case (\w+)$/gm)].map((match) => match[1]);
    assert.deepEqual(cases, [...mealTypes]);
    assert.deepEqual(recipeSchema.properties.mealTypes.items.enum, mealTypes);
  });

  test("meets strict mode: every property required and nothing extra", () => {
    function check(schema: Record<string, unknown>, path: string) {
      if (schema.type === "object") {
        const properties = schema.properties as Record<string, Record<string, unknown>>;
        assert.deepEqual([...(schema.required as string[])].sort(), Object.keys(properties).sort(), path);
        assert.equal(schema.additionalProperties, false, path);
        for (const [name, property] of Object.entries(properties)) check(property, `${path}.${name}`);
      } else if (schema.type === "array") {
        check(schema.items as Record<string, unknown>, `${path}[]`);
      }
    }
    check(recipeSchema, "recipe");
  });
});
