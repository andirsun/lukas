import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useTranslations } from "use-intl";
import type { Translator } from "../../api/errors.ts";
import { queryKeys } from "../../api/queries.ts";
import { feedback, setSoundEnabled, soundEnabled } from "../../feedback/feedback.ts";
import type { Locale } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { useTheme } from "../../theme/ThemeProvider.tsx";
import type { ThemePref } from "../../theme/theme-bootstrap.ts";
import { useToast } from "../../ui/Toast.tsx";
import type { Profile } from "../onboarding/onboarding-api.ts";
import { Choices, SettingSwitch, SettingsSection } from "./parts.tsx";
import { failureMessage, useSaveProfile } from "./use-profile.ts";

const LOCALES: readonly Locale[] = ["es", "en"];
const THEMES: readonly ThemePref[] = ["auto", "night", "day"];

/**
 * Language, theme and sound. The language applies at once (the catalogs switch, the URL stays)
 * and is saved on the profile; if saving fails it goes back, with a toast. Theme and sound belong
 * to this device.
 */
export function PreferencesSection() {
  const t = useTranslations("settings");
  const tRoot = useTranslations();
  const { pref, setPref } = useTheme();
  const [sound, setSound] = useState(soundEnabled);
  return (
    <SettingsSection title={t("preferences")}>
      <LanguageChoice />
      <Choices
        legend={tRoot("theme.label")}
        hint={t("theme_hint")}
        name="theme"
        value={pref}
        options={THEMES.map((value) => ({ value, label: tRoot(`theme.${value}`) }))}
        onChange={setPref}
      />
      <SettingSwitch
        label={t("sound")}
        hint={t("sound_hint")}
        checked={sound}
        onChange={(on) => {
          setSoundEnabled(on);
          setSound(on);
          // A taste of it, when it comes back on.
          if (on) feedback("tap");
        }}
      />
    </SettingsSection>
  );
}

function LanguageChoice() {
  const tRoot = useTranslations();
  const { locale, setLocale } = useLocale();
  const qc = useQueryClient();
  const save = useSaveProfile();
  const toast = useToast();

  const change = async (next: Locale) => {
    if (next === locale) return;
    // The shell follows the profile's language, so the cached profile changes with it.
    await qc.cancelQueries({ queryKey: queryKeys.me() });
    const before = qc.getQueryData<Profile>(queryKeys.me());
    if (before) qc.setQueryData(queryKeys.me(), { ...before, locale: next });
    setLocale(next);
    try {
      await save({ locale: next });
    } catch (problem) {
      if (before) qc.setQueryData(queryKeys.me(), before);
      setLocale(locale);
      toast.show({
        tone: "error",
        message: failureMessage(problem, tRoot as unknown as Translator),
      });
    }
  };

  return (
    <Choices
      legend={tRoot("language.label")}
      name="language"
      value={locale}
      // Each language is named in itself, and marked as such for screen readers.
      options={LOCALES.map((value) => ({ value, label: tRoot(`language.${value}`), lang: value }))}
      onChange={(next) => void change(next)}
    />
  );
}
