import { Insights } from "../features/insights/Insights.tsx";
import { screenMeta } from "../i18n/screen-meta.ts";

/** Spanish in the app; in the demo (which reuses this module), the demo's language. */
export const meta = ({ location }: { location: { pathname: string; search: string } }) =>
  screenMeta("insights", location);

/**
 * `/app/insights`: where the money goes, month by month, and what living costs. Signed in and
 * onboarded: the `/app` layout checks it. Its own chunk (with the charts' code split off again),
 * so home's first load does not carry it.
 */
export default function Route() {
  return <Insights />;
}
