import type { AssistantTool } from "./tool.ts";
import { READ_TOOLS } from "./tools/read.ts";
import { WRITE_TOOLS } from "./tools/write.ts";

/**
 * Every tool, in the fixed order clients list them: the read tools (spec §4.1), then the write
 * tools (§4.2). A transport serves only those whose `scope` the token carries.
 */
export const TOOLS: readonly AssistantTool<any, any>[] = [...READ_TOOLS, ...WRITE_TOOLS];
