import { describe, expect, it } from "vitest";
import { ApiProblem } from "./errors.ts";
import { shouldRetry } from "./query-client.ts";

const problem = (status: number) => new ApiProblem({ status, code: "x" });

describe("shouldRetry", () => {
  it("does not retry a client error", () => {
    expect(shouldRetry(0, problem(401))).toBe(false);
    expect(shouldRetry(0, problem(404))).toBe(false);
    expect(shouldRetry(0, problem(422))).toBe(false);
  });

  it("retries a lost connection or a server error, twice", () => {
    expect(shouldRetry(0, problem(0))).toBe(true);
    expect(shouldRetry(1, problem(503))).toBe(true);
    expect(shouldRetry(2, problem(503))).toBe(false);
  });

  it("retries an unexpected error", () => {
    expect(shouldRetry(0, new Error("boom"))).toBe(true);
  });
});
