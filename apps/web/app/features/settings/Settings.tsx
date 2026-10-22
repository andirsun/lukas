import { useTranslations } from "use-intl";
import { useMe } from "../../api/queries.ts";
import { PageHeader } from "../../ui/PageHeader.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { ManageFrame } from "../categories/CategoryDetail.tsx";
import { liveSignOut, type SignOutRequest } from "../home/use-sign-out.ts";
import { DeleteAccount } from "./DeleteAccount.tsx";
import { PasskeysSection } from "./PasskeysSection.tsx";
import { PreferencesSection } from "./PreferencesSection.tsx";
import { SettingLabel, SettingsSection } from "./parts.tsx";
import { livePasskeys, type PasskeysApi } from "./passkeys.ts";
import { TimeAndMoneySection } from "./TimeAndMoneySection.tsx";
import { type SaveFile, saveToDisk, useExport } from "./use-export.ts";

export type { SaveFile } from "./use-export.ts";

export interface SettingsProps {
  /** Better Auth's passkeys by default; stories stand in for them. */
  passkeys?: PasskeysApi;
  /** Ends the session after the account is deleted; Better Auth's by default. */
  signOut?: SignOutRequest;
  /** Where downloads go; the browser's by default. */
  save?: SaveFile;
}

/**
 * Settings (`/app/settings`, spec §2.7): language, theme and sound; time zone, and the currency
 * while it can still change; passkeys; import from Budge and the export; and deleting the
 * account. Reached from the avatar menu (phones) and the sidebar (wide screens).
 */
export function Settings({
  passkeys = livePasskeys,
  signOut = liveSignOut,
  save = saveToDisk,
}: SettingsProps) {
  const t = useTranslations("settings");
  const tManage = useTranslations("manage");
  const me = useMe().data;
  if (!me) throw new Error("Settings renders inside AppShell, which waits for the profile");
  const exporter = useExport(save);

  return (
    <ManageFrame>
      <PageHeader back={{ to: "/app", label: tManage("back"), short: tManage("back_short") }} />
      <main className="flex flex-col gap-(--space-4) pb-(--space-4)">
        <div className="flex flex-col gap-(--space-1)">
          <h1 className="m-0 font-display text-[28px] font-bold text-ink">{t("title")}</h1>
          <p className="m-0 break-all text-[14px] text-ink-muted">
            {t("signed_in_as", { email: me.email })}
          </p>
        </div>
        <PreferencesSection />
        <TimeAndMoneySection me={me} />
        <PasskeysSection passkeys={passkeys} timeZone={me.timezone} />
        <SettingsSection title={t("data.title")}>
          <div className="flex flex-col gap-(--space-2)">
            <SettingLabel label={t("data.import_title")} hint={t("data.import_lead")} />
            <PressLink to="/app/import" variant="secondary" className="self-start">
              {t("data.import_action")}
            </PressLink>
          </div>
          <div className="flex flex-col gap-(--space-2)">
            <SettingLabel label={t("data.export_title")} hint={t("data.export_lead")} />
            <div className="flex flex-wrap gap-(--space-2)">
              {(["json", "csv"] as const).map((format) => (
                <PressButton
                  key={format}
                  variant="secondary"
                  disabled={exporter.busy !== null}
                  aria-busy={exporter.busy === format || undefined}
                  onClick={() => void exporter.run(format)}
                >
                  {t(format === "json" ? "data.export_json" : "data.export_csv")}
                </PressButton>
              ))}
            </div>
          </div>
        </SettingsSection>
        <DeleteAccount
          email={me.email}
          signOut={signOut}
          onExport={(format) => void exporter.run(format)}
          exporting={exporter.busy !== null}
        />
      </main>
    </ManageFrame>
  );
}
