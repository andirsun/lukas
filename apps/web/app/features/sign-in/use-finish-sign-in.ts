import { useQueryClient } from "@tanstack/react-query";
import { useCallback } from "react";
import { useNavigate } from "react-router";
import { useApi, useClearSession } from "../../api/ApiProvider.tsx";
import { queryKeys } from "../../api/queries.ts";
import type { paths } from "../../api/schema";
import type { Locale } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { type AuthUser, destinationAfterSignIn } from "./auth.ts";

type Profile = paths["/v1/me"]["get"]["responses"][200]["content"]["application/json"];

export interface FinishSignIn {
  /** Who signed in, from the sign-in response (used when the profile can't be read). */
  user: AuthUser;
  /** `?next=` as given; only a same-origin path is honoured. */
  next: string | null;
  /** `?lang=` from the landing: the language a new user's profile starts in. */
  lang: Locale | null;
}

/**
 * What happens right after any sign-in (code, magic link, passkey): forget the previous person's
 * cached data, give a new user the language of the page they came from (`PATCH /v1/me`), switch
 * the app to the profile's language, and go to onboarding, `next` or the app.
 */
export function useFinishSignIn() {
  const api = useApi();
  const clearSession = useClearSession();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { setLocale } = useLocale();

  return useCallback(
    async ({ user, next, lang }: FinishSignIn) => {
      clearSession();
      let profile: Profile | null = null;
      try {
        profile = (await api.GET("/v1/me")).data ?? null;
        // Not onboarded yet means new here: the landing's language becomes theirs.
        if (profile && lang && profile.onboardingCompletedAt == null && profile.locale !== lang) {
          const { data } = await api.PATCH("/v1/me", { body: { locale: lang } });
          profile = data ?? profile;
        }
        if (profile) queryClient.setQueryData(queryKeys.me(), profile);
      } catch {
        // The profile is a nicety here: the person is signed in either way.
      }
      if (profile?.locale === "es" || profile?.locale === "en") setLocale(profile.locale);
      navigate(destinationAfterSignIn(profile ?? user, next), { replace: true });
    },
    [api, clearSession, queryClient, navigate, setLocale],
  );
}
