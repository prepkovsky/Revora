/** The app's `MealType` raw values, in its display order. A test checks them against the Swift enum. */
export const mealTypes = ["breakfast", "lunch", "dinner", "snack", "dessert", "drink"] as const;
export type MealType = (typeof mealTypes)[number];

export interface Ingredient {
  name: string;
  /** Free text, e.g. "200 g" or "2 tbsp". */
  quantity: string;
}

export interface Step {
  text: string;
  bullets: string[];
}

/** Like the Firestore shape, `title` is left out for a section without one. */
export interface RecipeSection<Item> {
  title?: string;
  items: Item[];
}

/** What the app gets back: a new recipe in the shape it saves. */
export interface ScannedRecipe {
  title: string;
  ingredientSections: RecipeSection<Ingredient>[];
  stepSections: RecipeSection<Step>[];
  mealTypes: MealType[];
}

export const recipeInstructions = `You read recipes from photos: cookbook pages, recipe cards, handwritten notes and screenshots.

Copy the recipe as written, in its original language. Don't translate, summarize, correct or add anything, and don't invent quantities or steps that aren't there.

- title: the recipe's name as written. Only if it has none, a short plain name for the dish in the recipe's language.
- ingredientSections and stepSections: use several sections only when the recipe groups its ingredients or steps under headings, like "For the sauce". Otherwise put everything in one section with title null.
- Each ingredient: quantity is the amount with its unit ("200 g", "2 tbsp", "a pinch"), or "" when there's none. name is the rest, including notes like "finely chopped".
- Each step: its text as one paragraph, without the step number or bullet character. Join lines that only wrap because of the page layout. bullets is for a list printed under the step, like the ingredients it adds; usually it's empty.
- mealTypes: the meals the recipe is clearly meant for, or none.
- If the photo shows several recipes, read the most prominent one.
- If there's no readable recipe in the photo, set isRecipe to false and leave everything else empty.`;

function sectionSchema(item: object) {
  return {
    type: "object",
    properties: {
      title: { type: ["string", "null"] },
      items: { type: "array", items: item },
    },
    required: ["title", "items"],
    additionalProperties: false,
  };
}

/** Structured output for the recipe model. Strict mode needs every field required and nothing extra. */
export const recipeSchema = {
  type: "object",
  properties: {
    isRecipe: { type: "boolean" },
    title: { type: "string" },
    ingredientSections: {
      type: "array",
      items: sectionSchema({
        type: "object",
        properties: { quantity: { type: "string" }, name: { type: "string" } },
        required: ["quantity", "name"],
        additionalProperties: false,
      }),
    },
    stepSections: {
      type: "array",
      items: sectionSchema({
        type: "object",
        properties: { text: { type: "string" }, bullets: { type: "array", items: { type: "string" } } },
        required: ["text", "bullets"],
        additionalProperties: false,
      }),
    },
    mealTypes: { type: "array", items: { type: "string", enum: mealTypes } },
  },
  required: ["isRecipe", "title", "ingredientSections", "stepSections", "mealTypes"],
  additionalProperties: false,
} as const;

/** The model's answer didn't match the schema it was given. */
export class MalformedReplyError extends Error {}

/**
 * The recipe in the model's answer, cleaned up like the editor does when saving,
 * or `null` when there's no recipe in the photo.
 */
export function scannedRecipe(reply: unknown): ScannedRecipe | null {
  const object = record(reply);
  if (typeof object.isRecipe !== "boolean") throw new MalformedReplyError("isRecipe");
  if (!object.isRecipe) return null;

  const recipe: ScannedRecipe = {
    title: tidy(string(object.title)),
    ingredientSections: sections(object.ingredientSections, (item) => {
      const ingredient = record(item);
      const name = tidy(string(ingredient.name));
      const quantity = tidy(string(ingredient.quantity));
      return name || quantity ? { name, quantity } : null;
    }),
    stepSections: sections(object.stepSections, (item) => {
      const step = record(item);
      const text = withoutListMarker(tidy(string(step.text)));
      const bullets = array(step.bullets)
        .map((bullet) => withoutListMarker(tidy(string(bullet))))
        .filter((bullet) => bullet !== "");
      return text || bullets.length > 0 ? { text, bullets } : null;
    }),
    mealTypes: mealTypes.filter((meal) => array(object.mealTypes).includes(meal)),
  };

  // A title on its own isn't worth opening the editor for.
  if (recipe.ingredientSections.length === 0 && recipe.stepSections.length === 0) return null;
  return recipe;
}

/**
 * Drops blank items and sections left empty. A section whose title is blank joins the
 * section above, the way the editor groups rows, so only the first one can be untitled.
 */
function sections<Item>(value: unknown, item: (value: unknown) => Item | null): RecipeSection<Item>[] {
  const result: RecipeSection<Item>[] = [];
  for (const sectionValue of array(value)) {
    const section = record(sectionValue);
    const title = section.title === null ? "" : tidy(string(section.title));
    const items = array(section.items)
      .map(item)
      .filter((value): value is Item => value !== null);
    if (items.length === 0) continue;

    const previous = result.at(-1);
    if (title === "" && previous) {
      previous.items.push(...items);
    } else {
      result.push(title === "" ? { items } : { title, items });
    }
  }
  return result;
}

/** The editor keeps each field on one line, so line breaks and runs of spaces become single spaces. */
function tidy(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

/** The app numbers steps itself, so a number or bullet copied from the page would show twice. */
function withoutListMarker(text: string): string {
  return text.replace(/^(?:\d{1,2}[.)]|[•·▪◦*–-])\s+/, "");
}

function record(value: unknown): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) throw new MalformedReplyError("object");
  return value as Record<string, unknown>;
}

function array(value: unknown): unknown[] {
  if (!Array.isArray(value)) throw new MalformedReplyError("array");
  return value;
}

function string(value: unknown): string {
  if (typeof value !== "string") throw new MalformedReplyError("string");
  return value;
}
