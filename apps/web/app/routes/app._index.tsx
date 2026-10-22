import { Home } from "../features/home/Home.tsx";
import { screenMeta } from "../i18n/screen-meta.ts";

/** Spanish in the app; in the demo (which reuses this module), the demo's language. */
export const meta = ({ location }: { location: { pathname: string; search: string } }) =>
  screenMeta("home", location);

/** `/app`: home. */
export default function HomeRoute() {
  return <Home />;
}
