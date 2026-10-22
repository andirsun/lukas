import type { ZodType } from "zod";
import { Problem } from "./schemas.ts";

export const jsonBody = <T extends ZodType>(schema: T) => ({
  content: { "application/json": { schema } },
  required: true,
});

export const jsonResponse = <T extends ZodType>(schema: T, description: string) => ({
  content: { "application/json": { schema } },
  description,
});

export const problems = (...statuses: number[]) =>
  Object.fromEntries(
    statuses.map((status) => [
      status,
      { content: { "application/problem+json": { schema: Problem } }, description: "Problem" },
    ]),
  );
