import postgres from "postgres";
import { runMigrations } from "./migrate.ts";

/** The role the API connects as. Migration 0001 grants to it by this name. */
export const APP_ROLE = "lukas_app";

const MIN_PASSWORD_LENGTH = 16;

function checkPassword(appPassword: string): void {
  if (appPassword.length < MIN_PASSWORD_LENGTH || appPassword === APP_ROLE) {
    throw new Error(
      `APP_DB_PASSWORD must be at least ${MIN_PASSWORD_LENGTH} characters and not the development password`,
    );
  }
}

/**
 * Creates the runtime role if it is missing and sets its password, nothing else. Roles live in the
 * server, not in a database, so this is also what a restore needs on a new server before the dump's
 * grants can be applied.
 */
export async function ensureAppRole(adminUrl: string, appPassword: string): Promise<void> {
  checkPassword(appPassword);
  const admin = postgres(adminUrl, { max: 1, onnotice: () => {} });
  try {
    await admin.unsafe(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${APP_ROLE}') THEN
          CREATE ROLE ${APP_ROLE} LOGIN NOSUPERUSER NOBYPASSRLS;
        END IF;
      END
      $$`);
    // `format('%L')` quotes the password as an SQL literal, so any character is stored as typed.
    // (ALTER ROLE cannot take a bind parameter.)
    const [statement] = await admin<{ sql: string }[]>`
      select format(
        'ALTER ROLE %I WITH LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE PASSWORD %L',
        ${APP_ROLE}::text,
        ${appPassword}::text
      ) as sql`;
    if (!statement) throw new Error("Could not build the role statement");
    await admin.unsafe(statement.sql);
  } finally {
    await admin.end();
  }
}

/**
 * Makes a database ready for the API: the runtime role exists with the given password, then every
 * pending migration is applied. Safe to run on every deploy: nothing is dropped, a role that
 * exists keeps its data and only has its password set again.
 *
 * This is the production counterpart of `docker/postgres/init.sql` (development only, with a
 * well-known password). It must run as the database owner, before the API starts, because
 * migration 0001 grants table privileges to the role.
 */
export async function prepareDatabase(adminUrl: string, appPassword: string): Promise<void> {
  await ensureAppRole(adminUrl, appPassword);
  const admin = postgres(adminUrl, { max: 1, onnotice: () => {} });
  try {
    await admin.unsafe(`GRANT USAGE ON SCHEMA public TO ${APP_ROLE}`);
  } finally {
    await admin.end();
  }
  await runMigrations(adminUrl);
}
