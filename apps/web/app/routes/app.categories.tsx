import { CategoriesPage } from "../features/categories/CategoriesPage.tsx";
import { screenMeta } from "../i18n/screen-meta.ts";

/** Spanish in the app; in the demo (which reuses this module), the demo's language. */
export const meta = ({ location }: { location: { pathname: string; search: string } }) =>
  screenMeta("categories", location);

/** `/app/categories`: create, edit, archive and restore categories. Signed in and onboarded: the `/app` layout checks it. */
export default function Route() {
  return <CategoriesPage />;
}
