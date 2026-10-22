// Development seed: signs in dev@lukas.test, imports the sample Budge CSV and sets budgets at each
// expense category's average monthly spending. Goes through the real routes, so it exercises the
// same code paths as the apps. Run: pnpm --filter @lukas/api seed
import { readFile } from "node:fs/promises";
import { monthOf, todayIn } from "@lukas/core";
import { createDb } from "@lukas/db";
import { createApp } from "../app.ts";
import { apiPathPrefix, loadConfig } from "../config.ts";
import { MemoryMailer } from "../mailer.ts";

const EMAIL = "dev@lukas.test";
const FIXTURE = new URL(
  "../../../../packages/importers/test/fixtures/budge-sample.csv",
  import.meta.url,
);

const config = loadConfig(process.env);
const { db, close } = createDb(config.DATABASE_URL);
const mailer = new MemoryMailer();
const app = createApp({ config, db, mailer });
const prefix = apiPathPrefix(config);

async function call<T>(
  method: string,
  path: string,
  init: { headers?: Record<string, string>; body?: unknown } = {},
) {
  const isForm = init.body instanceof FormData;
  const res = await app.request(`${prefix}${path}`, {
    method,
    headers: {
      ...(init.body && !isForm ? { "content-type": "application/json" } : {}),
      ...init.headers,
    },
    body: isForm ? (init.body as FormData) : init.body ? JSON.stringify(init.body) : undefined,
  });
  if (!res.ok && res.status !== 409)
    throw new Error(`${method} ${path} → ${res.status} ${await res.text()}`);
  return { res, body: res.status === 204 ? (undefined as T) : ((await res.json()) as T) };
}

await call("POST", "/auth/email-otp/send-verification-otp", {
  body: { email: EMAIL, type: "sign-in" },
});
const code = /(\d{6})$/.exec(mailer.lastTo(EMAIL)?.subject ?? "")?.[1];
const signIn = await call<{ user: { id: string } }>("POST", "/auth/sign-in/email-otp", {
  body: { email: EMAIL, otp: code },
});
const headers = { authorization: `Bearer ${signIn.res.headers.get("set-auth-token")}` };

const form = new FormData();
form.append("source", "budge");
form.append("file", new File([await readFile(FIXTURE)], "budge-sample.csv", { type: "text/csv" }));
const preview = await call<{
  id: string;
  stats: { averageMonthlySpending: { category: string; amount: number }[] };
}>("POST", "/v1/imports", { headers, body: form });
if (preview.res.status === 409) {
  console.log("Sample data already imported; nothing to do.");
} else {
  await call("POST", `/v1/imports/${preview.body.id}/confirm`, { headers });
  const categories = await call<{ id: string; name: string; kind: string }[]>(
    "GET",
    "/v1/categories",
    { headers },
  );
  const month = monthOf(todayIn("UTC"));
  for (const { category, amount } of preview.body.stats.averageMonthlySpending) {
    const match = categories.body.find((c) => c.name === category && c.kind === "expense");
    if (match && amount > 0) {
      await call("PUT", `/v1/categories/${match.id}/budget`, {
        headers,
        body: { amount, effectiveFrom: "2026-01" },
      });
    }
  }
  console.log(
    `Seeded ${EMAIL} with the sample Budge export (budgets from 2026-01, current month ${month}).`,
  );
}
await close();
