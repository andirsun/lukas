import { type QueryClient, useQueryClient } from "@tanstack/react-query";
import { useApi } from "../../api/ApiProvider.tsx";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { queryKeys } from "../../api/queries.ts";
import type { paths } from "../../api/schema";
import { dataOf, type Profile } from "../onboarding/onboarding-api.ts";

export type ProfilePatch = NonNullable<
  paths["/v1/me"]["patch"]["requestBody"]
>["content"]["application/json"];

/**
 * Saves profile fields (`PATCH /v1/me`) and puts the answer in the cache. A rejection is the API's
 * `ApiProblem` (a locked currency is 409 `currency_locked`).
 */
export function useSaveProfile(): (patch: ProfilePatch) => Promise<Profile> {
  const api = useApi();
  const qc = useQueryClient();
  return async (patch) => {
    const profile = dataOf(await api.PATCH("/v1/me", { body: patch }));
    qc.setQueryData(queryKeys.me(), profile);
    return profile;
  };
}

/**
 * Refetches everything but the profile: a new time zone moves "today" and every month's edges,
 * and a new currency is what every amount is shown in.
 */
export function refreshAllButProfile(qc: QueryClient): Promise<void> {
  return qc.invalidateQueries({ predicate: (query) => query.queryKey[0] !== queryKeys.me()[0] });
}

/** The words for a failure: the API's code in the catalog's words, or the generic line. */
export function failureMessage(problem: unknown, t: Translator): string {
  return problem instanceof ApiProblem ? problemMessage(problem, t) : t("errors.generic");
}
