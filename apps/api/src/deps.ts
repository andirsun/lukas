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
}
