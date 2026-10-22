import { Settings } from "../features/settings/Settings.tsx";
import { screenMeta } from "../i18n/screen-meta.ts";

/** Spanish in the app; in the demo (which reuses this module), the demo's language. */
export const meta = ({ location }: { location: { pathname: string; search: string } }) =>
  screenMeta("settings", location);

/**
 * `/app/settings`: language, theme, sound, time zone, currency, passkeys, import, export and
 * deleting the account. Signed in and onboarded: the `/app` layout checks it.
 */
export default function Route() {
  return <Settings />;
}
