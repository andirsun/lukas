import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "postgresql",
  schema: ["./src/schema/auth.ts", "./src/schema/domain.ts"],
  out: "./drizzle",
  casing: "snake_case",
});
