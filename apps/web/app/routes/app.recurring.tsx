import { RecurringPage } from "../features/recurring/RecurringPage.tsx";
import { screenMeta } from "../i18n/screen-meta.ts";

/** Spanish in the app; in the demo (which reuses this module), the demo's language. */
export const meta = ({ location }: { location: { pathname: string; search: string } }) =>
  screenMeta("recurring", location);

/** `/app/recurring`: the recurring transactions, with their next date. Signed in and onboarded: the `/app` layout checks it. */
export default function Route() {
  return <RecurringPage />;
}
