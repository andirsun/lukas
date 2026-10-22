import { describe, expect, test } from "vitest";
import { createApp } from "../src/app.ts";
import { TEST_CONFIG } from "./harness.ts";

/**
 * The OpenAPI contract the web's types and the Android app's client are generated from. Built
 * from the app with inert dependencies, as the generators do: no database, no mailer.
 */
interface Operation {
  operationId?: string;
  parameters?: { name: string; in: string; required?: boolean }[];
  responses: Record<string, { content?: Record<string, { schema: { $ref?: string } }> }>;
}
interface Document {
  paths: Record<string, Record<string, Operation>>;
  components: { schemas: Record<string, unknown> };
}

async function contract(): Promise<Document> {
  const refuse = () => {
    throw new Error("the OpenAPI document needs no database or mailer");
  };
  const app = createApp({
    config: {
      ...TEST_CONFIG,
      DATABASE_URL: "postgres://inert:inert@localhost:5432/inert",
      DATABASE_ADMIN_URL: "postgres://inert:inert@localhost:5432/inert",
    },
    db: new Proxy({}, { get: refuse }) as never,
    mailer: { send: refuse },
  });
  const res = await app.request("/openapi.json");
  expect(res.status).toBe(200);
  return (await res.json()) as Document;
}

const HTTP_METHODS = new Set(["get", "put", "post", "patch", "delete", "head", "options"]);

function operations(doc: Document): [string, Operation][] {
  return Object.entries(doc.paths).flatMap(([path, item]) =>
    Object.entries(item)
      .filter(([method]) => HTTP_METHODS.has(method))
      .map(([method, operation]): [string, Operation] => [`${method} ${path}`, operation]),
  );
}

function operation(doc: Document, id: string): Operation {
  const found = operations(doc).find(([, op]) => op.operationId === id);
  if (!found) throw new Error(`No operation ${id}`);
  return found[1];
}

describe("the OpenAPI contract", () => {
  test("every operation has a unique camelCase operationId", async () => {
    const doc = await contract();
    const all = operations(doc);
    expect(all.length).toBeGreaterThan(0);
    const missing = all.filter(([, op]) => !op.operationId).map(([name]) => name);
    expect(missing).toEqual([]);
    const ids = all.map(([, op]) => op.operationId as string);
    expect(new Set(ids).size).toBe(ids.length);
    for (const id of ids) expect(id).toMatch(/^[a-z][a-zA-Z0-9]*$/);
  });

  test("the DTOs are named component schemas", async () => {
    const doc = await contract();
    expect(Object.keys(doc.components.schemas)).toEqual(
      expect.arrayContaining([
        "Transaction",
        "Category",
        "Recurrence",
        "Summary",
        "Profile",
        "FileImport",
        "Problem",
        "CreateTransaction",
        "CreateTransactionsBatch",
      ]),
    );
    const created = operation(doc, "createTransaction").responses["201"];
    expect(created?.content?.["application/json"]?.schema.$ref).toBe(
      "#/components/schemas/Transaction",
    );
  });

  test("the create routes declare the Idempotency-Key header", async () => {
    const doc = await contract();
    const header = (id: string) =>
      operation(doc, id).parameters?.find((p) => p.in === "header" && p.name === "Idempotency-Key");
    expect(header("createTransaction")).toMatchObject({ required: false });
    expect(header("createTransactionsBatch")).toMatchObject({ required: true });
  });
});
