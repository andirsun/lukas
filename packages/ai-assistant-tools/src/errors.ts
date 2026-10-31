/**
 * A problem the model can act on: a category that does not exist, an amount of zero, a batch that
 * is too large. `code` is stable (it matches the API's problem codes where there is one), the
 * message is written for the model, and `data` carries what it needs to recover (for instance the
 * candidate category names). A transport shows it as a tool error, not as a crash.
 */
export class ToolError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly data?: unknown,
  ) {
    super(message);
    this.name = "ToolError";
  }
}
