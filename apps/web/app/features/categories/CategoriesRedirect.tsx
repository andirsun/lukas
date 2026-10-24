import { Navigate } from "react-router";
import { useAppPath } from "../home/app-path.ts";
import { SHOW_CATEGORIES } from "../home/home-storage.ts";

/**
 * The old `/app/categories` page (and the demo's): categories are managed in home's Categorías
 * tab now, so an old bookmark or link opens home on it instead of a 404.
 */
export function CategoriesRedirect() {
  const appPath = useAppPath();
  return <Navigate to={appPath()} state={SHOW_CATEGORIES} replace />;
}
