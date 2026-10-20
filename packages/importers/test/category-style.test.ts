import { expect, test } from "vitest";
import { categoryStyle, normalizeName } from "../src/index.ts";

test("normalizes names for matching", () => {
  expect(normalizeName("  Salário ")).toBe("salario");
});

test.each([
  ["Supermercado", { icon: "cart", color: "orange" }],
  ["Restaurante", { icon: "cutlery", color: "red" }],
  ["Salário", { icon: "salary", color: "green" }],
  ["suscripciones", { icon: "umbrella", color: "pink" }],
  ["Mascotas", { icon: "tag", color: "gray" }],
])("styles %s", (name, style) => {
  expect(categoryStyle(name)).toEqual(style);
});
