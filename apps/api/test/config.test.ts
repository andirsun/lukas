import { expect, test } from "vitest";
import { loadConfig } from "../src/config.ts";

const base = {
  DATABASE_URL: "postgres://lukas_app:x@db:5432/lukas",
  DATABASE_ADMIN_URL: "postgres://lukas:x@db:5432/lukas",
  BETTER_AUTH_SECRET: "s".repeat(40),
  API_URL: "https://api.lukas.app",
  WEB_URL: "https://lukas.app",
  MAIL_FROM: "Lukas <hola@lukas.app>",
  RESEND_API_KEY: "re_123",
  NODE_ENV: "production",
};

test("production refuses to trust a spoofable X-Forwarded-For without trusted proxies", () => {
  expect(() => loadConfig(base)).toThrow(/TRUSTED_PROXIES/);
});

test("production accepts trusted proxies or a platform client-IP header", () => {
  expect(
    loadConfig({ ...base, TRUSTED_PROXIES: "10.0.0.0/8, 172.16.0.0/12" }).TRUSTED_PROXIES,
  ).toEqual(["10.0.0.0/8", "172.16.0.0/12"]);
  expect(loadConfig({ ...base, CLIENT_IP_HEADER: "fly-client-ip" }).CLIENT_IP_HEADER).toBe(
    "fly-client-ip",
  );
});

test("invalid proxy ranges are rejected", () => {
  expect(() => loadConfig({ ...base, TRUSTED_PROXIES: "not-an-ip" })).toThrow(/TRUSTED_PROXIES/);
});
