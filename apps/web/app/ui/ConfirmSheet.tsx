import { useState } from "react";
import { useTranslations } from "use-intl";
import { PressButton } from "./PressButton.tsx";
import { Sheet } from "./Sheet.tsx";

export interface ConfirmSheetProps {
  open: boolean;
  onClose(): void;
  /** The question: "¿Archivar Ocio?". */
  title: string;
  /** What happens, and what does not. */
  body: string;
  /** "Sí, archivar". */
  confirmLabel: string;
  /** Does it; a rejection keeps the sheet open (the caller says why, in a toast). */
  onConfirm(): Promise<void>;
}

/**
 * Asks before a destructive action (archiving a category, deleting a recurrence): the question,
 * what it means, "Cancelar" and the action itself, in the danger color. Escape, the backdrop and
 * "Cancelar" all leave things as they were.
 */
export function ConfirmSheet({
  open,
  onClose,
  title,
  body,
  confirmLabel,
  onConfirm,
}: ConfirmSheetProps) {
  const t = useTranslations("common");
  const [busy, setBusy] = useState(false);

  const confirm = async () => {
    if (busy) return;
    setBusy(true);
    try {
      await onConfirm();
      onClose();
    } catch {
      // The caller reported it; the sheet stays for another try.
    } finally {
      setBusy(false);
    }
  };

  return (
    <Sheet open={open} onClose={onClose} title={title}>
      <div className="flex flex-col gap-(--space-4) pt-(--space-3)">
        <p className="m-0 text-[15px] text-ink">{body}</p>
        <div className="flex flex-col gap-(--space-2) min-[400px]:flex-row-reverse">
          <PressButton
            variant="secondary"
            className="flex-1 text-over"
            disabled={busy}
            aria-busy={busy}
            onClick={() => void confirm()}
          >
            {confirmLabel}
          </PressButton>
          <PressButton variant="ghost" className="flex-1" onClick={onClose}>
            {t("cancel")}
          </PressButton>
        </div>
      </div>
    </Sheet>
  );
}
