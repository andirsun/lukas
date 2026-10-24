/**
 * Comments and ideas (Settings, "Comentarios e ideas"): for now an email to the founder. The address is
 * here and nowhere else; the app has its own copy of it (apps/mobile/lib/settings/feedback.dart).
 */
export const FEEDBACK_EMAIL = "lukitas@andersonlaverde.com";

/** Set at build time from package.json (vite.config.ts); "dev" where the build was not given one. */
declare const __APP_VERSION__: string | undefined;
export const APP_VERSION = typeof __APP_VERSION__ === "string" ? __APP_VERSION__ : "dev";

/**
 * The `mailto:` link for a message to [FEEDBACK_EMAIL]: the subject and the body percent-encoded
 * (a `&`, `=`, `#` or `?` in either must not end the query, nor start another header).
 */
export function feedbackMailto({ subject, body }: { subject: string; body: string }): string {
  return `mailto:${FEEDBACK_EMAIL}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
}
