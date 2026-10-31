import type { ClientMetadataResourceFetch } from "@better-auth/oauth-provider";
import type { Db } from "@lukas/db";
import type { Config } from "./config.ts";
import type { Mailer } from "./mailer.ts";

export interface AppDeps {
  config: Config;
  db: Db;
  mailer: Mailer;
  /**
   * The clock the API reads "today" and "this month" from. Unset: the real one. The e2e stack pins
   * it with E2E_NOW (server.ts), and tests can pass their own.
   */
  now?: () => Date;
  /**
   * Fetches an assistant's Client ID Metadata Document. Unset: `@better-auth/cimd/node`'s, which
   * resolves DNS once, refuses private and special-use addresses, pins the address and never
   * follows a redirect. Tests pass their own.
   */
  fetchClientMetadata?: ClientMetadataResourceFetch;
}
