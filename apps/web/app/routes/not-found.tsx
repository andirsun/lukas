import { NotFound, notFoundMeta } from "../features/landing/NotFound.tsx";

export const meta = notFoundMeta;

/** `*`: every path that is not a page of the site (landing-only release only, see routes.ts). */
export default function NotFoundRoute() {
  return <NotFound />;
}
