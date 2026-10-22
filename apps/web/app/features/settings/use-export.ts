import { useState } from "react";
import { useTranslations } from "use-intl";
import { useApi } from "../../api/ApiProvider.tsx";
import type { Translator } from "../../api/errors.ts";
import { useToast } from "../../ui/Toast.tsx";
import { dataOf } from "../onboarding/onboarding-api.ts";
import { filenameFrom } from "./settings-model.ts";
import { failureMessage } from "./use-profile.ts";

export type ExportFormat = "json" | "csv";

/** Hands a downloaded file to the browser. */
export type SaveFile = (blob: Blob, filename: string) => void;

/** The browser's download: a temporary link to the file, clicked. */
export const saveToDisk: SaveFile = (blob, filename) => {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.rel = "noopener";
  link.hidden = true;
  document.body.append(link);
  link.click();
  link.remove();
  // Long enough for the download to start, on any browser.
  setTimeout(() => URL.revokeObjectURL(url), 60_000);
};

/**
 * Downloads the export (`GET /v1/me/export`) through the API client, with the session's cookie,
 * as a file named by the server. Fetched rather than navigated to, so a failure is a toast on
 * this page instead of an error page. `busy` is the format being prepared.
 */
export function useExport(save: SaveFile) {
  const api = useApi();
  const t = useTranslations("settings.data");
  const tRoot = useTranslations() as unknown as Translator;
  const toast = useToast();
  const [busy, setBusy] = useState<ExportFormat | null>(null);

  const run = async (format: ExportFormat) => {
    if (busy) return;
    setBusy(format);
    try {
      const result = await api.GET("/v1/me/export", {
        params: { query: { format } },
        parseAs: "blob",
      });
      const blob = dataOf(result) as Blob;
      const filename = filenameFrom(
        result.response.headers.get("content-disposition"),
        `lukas-export.${format}`,
      );
      save(blob, filename);
      toast.show({ message: t("exported", { file: filename }) });
    } catch (problem) {
      toast.show({ tone: "error", message: failureMessage(problem, tRoot) });
    } finally {
      setBusy(null);
    }
  };

  return { busy, run };
}
