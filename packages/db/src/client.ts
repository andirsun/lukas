import { sql } from "drizzle-orm";
import { drizzle, type PostgresJsDatabase } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as authSchema from "./schema/auth.ts";
import * as domainSchema from "./schema/domain.ts";

export const schema = { ...authSchema, ...domainSchema };
export type Db = PostgresJsDatabase<typeof schema>;
export type Tx = Parameters<Parameters<Db["transaction"]>[0]>[0];

export function createDb(url: string): { db: Db; close(): Promise<void> } {
  const client = postgres(url, { max: 10, onnotice: () => {} });
  return { db: drizzle(client, { schema }), close: () => client.end() };
}

/** Runs `fn` in a transaction scoped to `userId`; row-level security only exposes that user's rows. */
export function withUser<T>(db: Db, userId: string, fn: (tx: Tx) => Promise<T>): Promise<T> {
  return db.transaction(async (tx) => {
    await tx.execute(sql`select set_config('app.user_id', ${userId}, true)`);
    return fn(tx);
  });
}
