/**
 * The consent screen's rules (spec §6.1), apart from React: what the signed query asks for, where
 * the assistant comes from, and what a refusal from Better Auth means for the person.
 */

/** The scopes the API offers (apps/api/src/auth.ts, OAUTH_SCOPES). */
export type Permission = "finance:read" | "finance:write" | "offline_access";

const PERMISSIONS: readonly Permission[] = ["finance:read", "finance:write", "offline_access"];

/** What Better Auth's signed redirect to `/oauth/consent` says, as far as the screen needs it. */
export interface ConsentRequest {
  clientId: string;
  /** The requested scopes we know, in a fixed order (read, write, offline); unknown ones dropped. */
  permissions: Permission[];
  /** When the signature stops being valid (`exp`, seconds), or null when it has none. */
  expiresAt: Date | null;
}

/** The request in the page's query, or null when it has no client_id or no signature. */
export function parseConsentQuery(search: string): ConsentRequest | null {
  const params = new URLSearchParams(search);
  const clientId = params.get("client_id");
  if (!clientId || !params.get("sig")) return null;
  const asked = new Set((params.get("scope") ?? "").split(" ").filter(Boolean));
  const exp = Number(params.get("exp"));
  return {
    clientId,
    permissions: PERMISSIONS.filter((p) => asked.has(p)),
    expiresAt: Number.isFinite(exp) && exp > 0 ? new Date(exp * 1000) : null,
  };
}

/** The query Better Auth signed, as `oauth_query` wants it: the page's search without the `?`. */
export const oauthQueryOf = (search: string) => (search.startsWith("?") ? search.slice(1) : search);

const hostOf = (url: string | null | undefined, https: boolean): string | null => {
  if (!url) return null;
  try {
    const parsed = new URL(url);
    if (parsed.protocol === "https:") return parsed.host;
    return !https && parsed.protocol === "http:" ? parsed.host : null;
  } catch {
    return null;
  }
};

/**
 * Where the assistant comes from: the host its client_id lives on when the id is an https URL
 * (a Client ID Metadata Document, which only that host can publish), else its website's host.
 * This is what tells a real Claude from a copy that calls itself Claude. Same rule as the API's
 * `GET /v1/me/assistants` (routes/assistants.ts).
 */
export function clientDomain(clientId: string, clientUri?: string | null): string | null {
  return hostOf(clientId, true) ?? hostOf(clientUri, false);
}

/** The public fields of an OAuth client (`GET /api/auth/oauth2/public-client`). */
export interface PublicClient {
  name: string;
  /** Its logo, when it gave an https one. */
  icon: string | null;
  domain: string | null;
}

/** Reads Better Auth's answer (`client_name`, `logo_uri`, `client_uri`, RFC 7591 names). */
export function publicClientFrom(clientId: string, body: unknown): PublicClient {
  const fields = typeof body === "object" && body !== null ? (body as Record<string, unknown>) : {};
  const text = (key: string) => (typeof fields[key] === "string" ? (fields[key] as string) : null);
  const logo = text("logo_uri");
  return {
    name: text("client_name")?.trim() || clientId,
    icon: logo && hostOf(logo, true) ? logo : null,
    domain: clientDomain(clientId, text("client_uri")),
  };
}

/**
 * Why consent can't go on, as the screen says it: `expired` (the signed link ran out or was
 * tampered with, or the assistant is unknown: start again from the assistant), `guest` (save
 * the progress first), `network` (no connection), or `generic`.
 */
export type ConsentProblem = "expired" | "guest" | "network" | "generic";

const START_AGAIN = new Set([
  "invalid_signature",
  "invalid_request",
  "invalid_client",
  "not_found",
  "access_denied",
]);

/**
 * A refusal from Better Auth, read from its status and body. Its errors come as `{ code }`
 * (ours: `guest_cannot_authorize`) or as OAuth's `{ error }` (`invalid_signature`).
 */
export function consentProblemFrom(status: number, body: unknown): ConsentProblem {
  if (status === 0) return "network";
  const fields = typeof body === "object" && body !== null ? (body as Record<string, unknown>) : {};
  const code = [fields.code, fields.error].find((v): v is string => typeof v === "string");
  if (code === "guest_cannot_authorize") return "guest";
  if (code && START_AGAIN.has(code.toLowerCase())) return "expired";
  if (status === 404) return "expired";
  return "generic";
}
