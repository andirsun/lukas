import { createTranslator } from "use-intl/core";
import { describe, expect, it } from "vitest";
import { CATALOGS } from "../i18n/catalog.ts";

const { es, en } = CATALOGS;

import { ApiProblem, problemFromResponse, problemMessage } from "./errors.ts";

const tEs = createTranslator({ locale: "es", messages: es, onError: () => {} });
const tEn = createTranslator({ locale: "en", messages: en, onError: () => {} });

const problem = (code: string, status = 409) => new ApiProblem({ status, code });

describe("problemMessage", () => {
  it("maps category_name_taken to the Spanish string", () => {
    expect(problemMessage(problem("category_name_taken"), tEs)).toBe(es.errors.category_name_taken);
    expect(problemMessage(problem("category_name_taken"), tEs)).toBe(
      "Ya tienes una categoría con ese nombre.",
    );
  });

  it("maps it to the English string too", () => {
    expect(problemMessage(problem("category_name_taken"), tEn)).toBe(en.errors.category_name_taken);
  });

  it("explains that sign-in is closed to an address, in both languages", () => {
    const closed = problem("sign_in_not_allowed", 403);
    expect(problemMessage(closed, tEs)).toBe(
      "Lukitas todavía no está abierto al público. Si quieres probarlo, escríbele a quien te invitó.",
    );
    expect(problemMessage(closed, tEs)).toBe(es.errors.sign_in_not_allowed);
    expect(problemMessage(closed, tEn)).toBe(en.errors.sign_in_not_allowed);
    expect(problemMessage(closed, tEn)).not.toBe(en.errors.generic);
  });

  it("falls back to errors.generic for unknown codes", () => {
    expect(problemMessage(problem("totally_new_code"), tEs)).toBe(es.errors.generic);
    expect(problemMessage(problem("totally_new_code"), tEn)).toBe(en.errors.generic);
  });

  it("never shows the API's English detail", () => {
    const withDetail = new ApiProblem({ status: 409, code: "category_name_taken", detail: "x" });
    expect(problemMessage(withDetail, tEs)).not.toContain("x");
  });

  it("explains a lost connection", () => {
    expect(problemMessage(new ApiProblem({ status: 0, code: "network_error" }), tEs)).toBe(
      es.errors.network_error,
    );
  });
});

describe("problemFromResponse", () => {
  const json = (body: unknown, status: number, type = "application/problem+json") =>
    new Response(JSON.stringify(body), { status, headers: { "content-type": type } });

  it("reads an RFC 9457 body", async () => {
    const result = await problemFromResponse(
      json(
        {
          type: "about:blank",
          title: "Unprocessable Content",
          status: 422,
          code: "validation_failed",
          detail: "The request is invalid",
          errors: [{ path: "name", message: "Required" }],
        },
        422,
      ),
    );
    expect(result).toBeInstanceOf(ApiProblem);
    expect(result).toBeInstanceOf(Error);
    expect(result.status).toBe(422);
    expect(result.code).toBe("validation_failed");
    expect(result.detail).toBe("The request is invalid");
    expect(result.errors).toEqual([{ path: "name", message: "Required" }]);
  });

  it("keeps the HTTP status when the body disagrees or is missing", async () => {
    const result = await problemFromResponse(json({ code: "not_found" }, 404));
    expect(result.status).toBe(404);
    expect(result.code).toBe("not_found");
    expect(result.errors).toEqual([]);
  });

  it("copes with a non-JSON body from a proxy", async () => {
    const gateway = await problemFromResponse(
      new Response("<html>Bad gateway</html>", { status: 502 }),
    );
    expect(gateway.status).toBe(502);
    expect(gateway.code).toBe("internal_error");

    const other = await problemFromResponse(new Response("nope", { status: 418 }));
    expect(other.code).toBe("http_error");
  });
});
