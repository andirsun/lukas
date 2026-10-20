import type { Db } from "@lukas/db";
import type { Config } from "./config.ts";
import type { Mailer } from "./mailer.ts";

export interface AppDeps {
  config: Config;
  db: Db;
  mailer: Mailer;
}
