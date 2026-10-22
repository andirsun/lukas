import { ensureAppRole, prepareDatabase } from "../bootstrap.ts";

// With --role-only: just the role and its password (a restore creates the tables from a dump).
const roleOnly = process.argv.includes("--role-only");

const adminUrl = process.env.DATABASE_ADMIN_URL;
if (!adminUrl) throw new Error("DATABASE_ADMIN_URL is required");
const appPassword = process.env.APP_DB_PASSWORD;
if (!appPassword) throw new Error("APP_DB_PASSWORD is required");

if (roleOnly) {
  await ensureAppRole(adminUrl, appPassword);
  console.log("Role lukas_app ready");
} else {
  await prepareDatabase(adminUrl, appPassword);
  console.log("Database ready: lukas_app role set, migrations applied");
}
