import { Link } from "react-router";
import { useTranslations } from "use-intl";

export interface BottomBarProps {
  /** The current section; one the bar has no tab for (categories, say) marks none. */
  current: string;
  /** Opens the add sheet. */
  onAdd(): void;
  /** Tabs whose screen does not exist yet: shown, marked "pronto", and not a link. */
  soon?: readonly ("home" | "insights")[];
  /** Where the app lives: `/app`, or `/demo` in the demo. */
  base?: string;
}

const TABS = [
  { key: "home", to: "", glyph: "🏠" },
  { key: "insights", to: "/insights", glyph: "📊" },
] as const;

/**
 * Phone navigation: Inicio · ＋ · Análisis. The raised ＋ (the bar's only `brand` element) opens
 * the add sheet; recurring, categories and settings live in the avatar menu. On wide screens the
 * layout shows `Sidebar` instead.
 */
export function BottomBar({ current, onAdd, soon = [], base = "/app" }: BottomBarProps) {
  const t = useTranslations("nav");
  const tab = (key: (typeof TABS)[number]["key"]) => {
    const { to, glyph } = TABS.find((x) => x.key === key) as (typeof TABS)[number];
    if (soon.includes(key)) {
      return (
        <span className="lk-tab is-soon">
          <span className="lk-tab-ico" aria-hidden="true">
            {glyph}
          </span>
          {t(key)}
          <span className="lk-soon">{t("soon")}</span>
        </span>
      );
    }
    return (
      <Link
        to={`${base}${to}`}
        className="lk-tab"
        aria-current={current === key ? "page" : undefined}
      >
        <span className="lk-tab-ico" aria-hidden="true">
          {glyph}
        </span>
        {t(key)}
      </Link>
    );
  };

  return (
    <nav aria-label={t("label")} className="lk-tabbar">
      {tab("home")}
      {/* Lukitas lands on the ＋ when something is celebrated: free space, no text under him. */}
      <button
        type="button"
        className="lk-plus"
        aria-label={t("add")}
        onClick={onAdd}
        data-celebration-anchor="64"
      >
        <span aria-hidden="true">＋</span>
      </button>
      {tab("insights")}
    </nav>
  );
}
