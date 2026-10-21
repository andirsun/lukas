import type { SupportedCurrency } from "@lukas/core";
import { useQuery } from "@tanstack/react-query";
import { useApi } from "../../api/ApiProvider.tsx";
import type { ApiClient } from "../../api/client.ts";
import { ApiProblem } from "../../api/errors.ts";
import type { paths } from "../../api/schema";
import type { Locale } from "../../i18n/format.ts";
import type { ImportDto } from "./import-state.ts";
import {
  SUGGESTED_CATEGORIES,
  type SuggestedCategory,
  suggestionFor,
} from "./suggested-categories.ts";

export type Profile = paths["/v1/me"]["get"]["responses"][200]["content"]["application/json"];
export type Category =
  paths["/v1/categories"]["get"]["responses"][200]["content"]["application/json"][number];

/** The data of a successful call (failures already threw an `ApiProblem`). */
export function dataOf<T>(result: { data?: T; response: Response }): T {
  if (result.data === undefined) {
    throw new ApiProblem({ status: result.response.status, code: "internal_error" });
  }
  return result.data;
}

export async function uploadImport(api: ApiClient, file: File): Promise<ImportDto> {
  // openapi-fetch sends FormData as is (the browser sets the multipart boundary).
  const form = new FormData();
  form.append("source", "budge");
  form.append("file", file);
  return dataOf(
    await api.POST("/v1/imports", { body: form as unknown as { source: "budge"; file: string } }),
  );
}

export async function patchCurrency(api: ApiClient, code: SupportedCurrency): Promise<Profile> {
  return dataOf(await api.PATCH("/v1/me", { body: { currency: code } }));
}

/** Every category, archived ones included: what "already exists" is decided against. */
export async function allCategories(api: ApiClient): Promise<Category[]> {
  return dataOf(
    await api.GET("/v1/categories", { params: { query: { includeArchived: "true" } } }),
  );
}

/** The body that creates a suggested category, named in the person's language. */
export function suggestionBody(suggestion: SuggestedCategory, locale: Locale) {
  return {
    name: suggestion.names[locale],
    kind: suggestion.kind,
    icon: suggestion.glyph,
    color: suggestion.tint,
    sortOrder: SUGGESTED_CATEGORIES.indexOf(suggestion),
  };
}

const nameTaken = (problem: unknown) =>
  problem instanceof ApiProblem && problem.code === "category_name_taken";

/**
 * Creates the suggestions in `keys` that the person doesn't have yet. It reads the categories
 * first (archived ones count as existing: a deselected suggestion stays deselected), and a 409
 * `category_name_taken` counts as created, so after a partial failure (a lost connection halfway)
 * running it again finishes the job instead of failing on the ones already there.
 */
export async function createSuggestions(
  api: ApiClient,
  keys: ReadonlySet<string>,
  locale: Locale,
): Promise<void> {
  const existing = new Set(
    (await allCategories(api)).map((c) => suggestionFor(c.name)?.key).filter(Boolean),
  );
  await Promise.all(
    SUGGESTED_CATEGORIES.filter((s) => keys.has(s.key) && !existing.has(s.key)).map(async (s) => {
      try {
        await api.POST("/v1/categories", { body: suggestionBody(s, locale) });
      } catch (problem) {
        if (!nameTaken(problem)) throw problem;
      }
    }),
  );
}

/**
 * Whether the account has any transaction: then its currency is locked, and what it has is what
 * the currency step shows.
 */
export function useHasTransactions() {
  const api = useApi();
  return useQuery({
    queryKey: ["onboarding", "has-transactions"],
    queryFn: async ({ signal }) =>
      dataOf(await api.GET("/v1/transactions", { params: { query: { limit: 1 } }, signal })).items
        .length > 0,
  });
}
