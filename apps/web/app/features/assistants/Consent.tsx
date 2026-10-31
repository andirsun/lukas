import { useQuery } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router";
import { useTranslations } from "use-intl";
import { PressButton } from "../../ui/PressButton.tsx";
import { FieldError, ScreenTitle, SignInScreen } from "../sign-in/SignInScreen.tsx";
import { type ConsentApi, ConsentError } from "./consent-api.ts";
import {
  type ConsentProblem,
  oauthQueryOf,
  type Permission,
  parseConsentQuery,
} from "./consent-model.ts";

const PERMISSION_KEY = {
  "finance:read": "permissions.read",
  "finance:write": "permissions.write",
  offline_access: "permissions.offline",
} as const satisfies Record<Permission, string>;

/** Where the browser goes once the person answers: away from Lukitas, to the assistant. */
const leaveTo = (url: string) => window.location.assign(url);

export interface ConsentProps {
  /** Better Auth's oauth-provider by default; stories stand in for it. */
  api: ConsentApi;
  /** A guest (no email yet): the API refuses them, so they are asked to save their progress. */
  guest: boolean;
  /** Follows the URL the answer returns; a full page load by default. */
  go?: (url: string) => void;
  /** Now, to tell an expired link before asking anything; the clock by default. */
  now?: () => Date;
}

const problemOf = (error: unknown): ConsentProblem =>
  error instanceof ConsentError ? error.problem : "generic";

/**
 * `/oauth/consent` (spec §6.1): Better Auth sends the browser here, with a signed query, when an
 * assistant (Claude, ChatGPT) asks to connect. "<Name> quiere acceder a tus finanzas", its logo,
 * and the domain its client_id lives on, which is what tells a real Claude from a copy; then
 * what it could do, in plain words per scope. Permitir and Cancelar post the signed query back
 * and follow where Better Auth says (the assistant, with a code or `access_denied`).
 *
 * A guest gets "Guarda tu progreso" instead of Permitir. A link that ran out (ten minutes) or was
 * changed says to start again from the assistant. The heading takes the focus on arrival.
 */
export function Consent({ api, guest, go = leaveTo, now = () => new Date() }: ConsentProps) {
  const t = useTranslations("consent");
  const tErrors = useTranslations("errors");
  const tCommon = useTranslations("common");
  const { search } = useLocation();
  const [request] = useState(() => parseConsentQuery(search));
  const [expiredOnArrival] = useState(
    () => !request || (request.expiresAt !== null && request.expiresAt < now()),
  );
  const client = useQuery({
    queryKey: ["oauth-client", request?.clientId],
    queryFn: () => api.client(request?.clientId ?? ""),
    enabled: !expiredOnArrival,
    retry: false,
    staleTime: Number.POSITIVE_INFINITY,
  });
  const [busy, setBusy] = useState<"allow" | "cancel" | null>(null);
  const [problem, setProblem] = useState<ConsentProblem | null>(null);
  // A ref, not state: two quick taps must not post twice.
  const inFlight = useRef(false);
  const heading = useRef<HTMLHeadingElement>(null);

  const clientProblem = client.isError ? problemOf(client.error) : null;
  const expired = expiredOnArrival || clientProblem === "expired" || problem === "expired";
  const asGuest = guest || problem === "guest";
  const ready = client.data !== undefined;

  // The screen appears without a tap on a link: a screen reader starts at its heading.
  useEffect(() => {
    if (expired || ready) heading.current?.focus();
  }, [expired, ready]);

  async function answer(accept: boolean) {
    if (inFlight.current) return;
    inFlight.current = true;
    setBusy(accept ? "allow" : "cancel");
    setProblem(null);
    try {
      go(await api.decide(accept, oauthQueryOf(search)));
      // Busy until the page is gone: the assistant's address is loading.
    } catch (error) {
      inFlight.current = false;
      setBusy(null);
      setProblem(problemOf(error));
    }
  }

  if (expired) {
    return (
      <SignInScreen mood="worried">
        <ScreenTitle ref={heading} focusable>
          {t("expired.title")}
        </ScreenTitle>
        <p className="m-0 text-center text-ink-muted">{t("expired.body")}</p>
      </SignInScreen>
    );
  }

  if (!client.data) {
    return (
      <SignInScreen>
        {clientProblem ? (
          <>
            <FieldError id="consent-error">
              {clientProblem === "network" ? tErrors("network_error") : t("failed")}
            </FieldError>
            <PressButton variant="secondary" onClick={() => void client.refetch()}>
              {tCommon("retry")}
            </PressButton>
          </>
        ) : (
          <p role="status" className="m-0 text-ink-muted">
            {t("loading")}
          </p>
        )}
      </SignInScreen>
    );
  }

  const { name, icon, domain } = client.data;
  const failure =
    problem === "network" ? tErrors("network_error") : problem === "generic" ? t("failed") : null;

  return (
    <SignInScreen>
      {icon && (
        <img
          src={icon}
          alt={t("logo_alt", { name })}
          width={56}
          height={56}
          referrerPolicy="no-referrer"
          className="size-14 rounded-lg border-2 border-stroke bg-surface-row object-contain"
        />
      )}
      <ScreenTitle ref={heading} focusable>
        {t("title", { name })}
      </ScreenTitle>
      <div className="flex w-full flex-col items-center gap-(--space-1) rounded-md border-2 border-stroke bg-surface-row p-(--space-3) text-center">
        {domain ? (
          <>
            <p className="m-0 break-all text-[17px] font-bold text-ink">{t("from", { domain })}</p>
            <p className="m-0 text-[14px] text-ink-muted">{t("domain_hint")}</p>
          </>
        ) : (
          <p className="m-0 text-[15px] font-bold text-ink">{t("no_domain")}</p>
        )}
      </div>
      {request && request.permissions.length > 0 && (
        <div className="flex w-full flex-col gap-(--space-2)">
          <h2 className="m-0 text-[15px] font-bold text-ink">{t("permissions_title")}</h2>
          <ul className="m-0 flex list-disc flex-col gap-(--space-2) pl-(--space-5) text-ink marker:text-ink-muted">
            {request.permissions.map((permission) => (
              <li
                key={permission}
                className={permission === "offline_access" ? "text-[14px] text-ink-muted" : ""}
              >
                {t(PERMISSION_KEY[permission])}
              </li>
            ))}
          </ul>
          <p className="m-0 text-[14px] text-ink-muted">{t("revoke_hint")}</p>
        </div>
      )}
      {asGuest && (
        <section
          aria-labelledby="consent-guest"
          className="flex w-full flex-col gap-(--space-1) rounded-md border-2 border-gold p-(--space-3)"
        >
          <h2 id="consent-guest" className="m-0 font-display text-[20px] font-bold text-ink">
            {t("guest.title")}
          </h2>
          <p className="m-0 text-[15px] text-ink">{t("guest.body")}</p>
        </section>
      )}
      {failure && <FieldError id="consent-error">{failure}</FieldError>}
      <div className="flex w-full flex-col gap-(--space-2)">
        {!asGuest && (
          <PressButton
            className="w-full"
            disabled={busy !== null}
            aria-busy={busy === "allow" || undefined}
            aria-describedby={failure ? "consent-error" : undefined}
            onClick={() => void answer(true)}
          >
            {busy === "allow" ? t("allowing") : t("allow")}
          </PressButton>
        )}
        <PressButton
          variant={asGuest ? "secondary" : "ghost"}
          className="w-full"
          disabled={busy !== null}
          aria-busy={busy === "cancel" || undefined}
          onClick={() => void answer(false)}
        >
          {t("cancel")}
        </PressButton>
      </div>
    </SignInScreen>
  );
}
