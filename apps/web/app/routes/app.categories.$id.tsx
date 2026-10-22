import { CategoryDetail } from "../features/categories/CategoryDetail.tsx";
import { screenMeta } from "../i18n/screen-meta.ts";

/** Spanish in the app; in the demo (which reuses this module), the demo's language. */
export const meta = ({ location }: { location: { pathname: string; search: string } }) =>
  screenMeta("categories.detail", location);

/** `/app/categories/:id`: one category's month (`?month=`): its budget and its transactions. Signed in and onboarded: the `/app` layout checks it. */
export default function Route() {
  return <CategoryDetail />;
}
