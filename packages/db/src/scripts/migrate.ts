import { runMigrations } from "../migrate.ts";

const url = process.env.DATABASE_ADMIN_URL;
if (!url) throw new Error("DATABASE_ADMIN_URL is required");
await runMigrations(url);
console.log("Migrations applied");
