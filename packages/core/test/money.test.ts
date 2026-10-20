import { describe, expect, test } from "vitest";
import { InvalidAmountError, parseDecimalToMinor } from "../src/index.ts";

describe("parseDecimalToMinor", () => {
  test.each([
    ["-30.70", -3070],
    ["-16", -1600],
    ["5", 500],
    ["-4.6", -460],
    [" 6200.00 ", 620000],
    ["0.29", 29],
  ])("parses %j as %i cents", (input, expected) => {
    expect(parseDecimalToMinor(input)).toBe(expected);
  });

  test.each(["", "abc", "1,50", "1.234", "--1", "1e3", "."])("rejects %j", (input) => {
    expect(() => parseDecimalToMinor(input)).toThrow(InvalidAmountError);
  });
});
