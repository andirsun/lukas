import { Link } from "react-router";
import { useTranslations } from "use-intl";

export interface BottomBarProps {
  /** The current section; one the bar has no tab for (categories, say) marks none. */
  current: string;
  /** Opens the add sheet. */
  onAdd(): void;
  /** Tabs whose screen does not exist yet: shown, marked "pronto", and not a link. */
  soon?: readonly ("home" | "insights")[];
}

const TABS = [
  { key: "home", to: "/app", glyph: "🏠" },
  { key: "insights", to: "/app/insights", glyph: "📊" },
] as const;

/**
 * Phone navigation: Inicio · ＋ · Análisis. The raised ＋ (the bar's only `brand` element) opens
 * the add sheet; recurring, categories and settings live in the avatar menu. On wide screens the
 * layout shows `Sidebar` instead.
 */
export function BottomBar({ current, onAdd, soon = [] }: BottomBarProps) {
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
      <Link to={to} className="lk-tab" aria-current={current === key ? "page" : undefined}>
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
      <button type="button" className="lk-plus" aria-label={t("add")} onClick={onAdd}>
        <span aria-hidden="true">＋</span>
      </button>
      {tab("insights")}
    </nav>
  );
}
