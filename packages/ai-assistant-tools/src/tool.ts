import type { z } from "zod";
import type { Lukitas } from "./lukitas.ts";

/** What a tool runs with: the person's Lukitas, who they are (for idempotency keys) and a clock. */
export interface ToolContext {
  lukitas: Lukitas;
  userId: string;
  now: () => Date;
}

/** A tool's answer: structured content for the client, and a short text summary of it. */
export interface ToolResult<O> {
  structured: O;
  text: string;
}

/**
 * One assistant tool, independent of any transport: a name and a description for the model, zod
 * schemas for its input and output (plain objects, so a transport can turn them into JSON
 * Schema), the scope it needs, and a handler. Handlers throw `ToolError` for problems the model can
 * fix.
 */
export interface AssistantTool<I extends z.ZodType, O extends z.ZodType> {
  name: string;
  title: string;
  description: string;
  scope: "finance:read" | "finance:write";
  annotations: {
    readOnlyHint: boolean;
    destructiveHint: boolean;
    idempotentHint: boolean;
    openWorldHint: false;
  };
  input: I;
  output: O;
  handler(input: z.infer<I>, ctx: ToolContext): Promise<ToolResult<z.infer<O>>>;
}

/** Declares a tool, checking at compile time that its handler fits its schemas. */
export function defineTool<I extends z.ZodObject, O extends z.ZodObject>(
  tool: AssistantTool<I, O>,
): AssistantTool<I, O> {
  return tool;
}

/** The annotations every read tool shares. */
export const READ_ONLY = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
} as const;
