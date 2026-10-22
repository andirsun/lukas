import type { TransactionDto } from "@lukas/core";
import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { AddTransactionSheet } from "./AddTransactionSheet.tsx";
import {
  type TransactionActions,
  type TransactionEvent,
  useTransactionActions,
} from "./use-add-transaction.ts";

interface SheetRequest {
  editing?: TransactionDto;
  categoryId?: string;
  focusName?: boolean;
}

interface TransactionSheetContext {
  /** Opens the sheet to add, optionally in a category. */
  openAdd(categoryId?: string): void;
  /** Opens the sheet on an existing transaction. */
  openEdit(tx: TransactionDto, options?: { focusName?: boolean }): void;
  actions: TransactionActions;
  /** The latest save or payment in this session, for Lukitas on home. */
  lastEvent: TransactionEvent | null;
  /** Transactions just brought back by Deshacer: their rows slide in when they reappear. */
  restored: ReadonlySet<string>;
}

/** How long a restored transaction counts as just restored (its row mounts well within it). */
const RESTORED_MS = 2000;

const Context = createContext<TransactionSheetContext | null>(null);

export interface TransactionSheetProviderProps {
  children: ReactNode;
  /** The account's currency and the person's time zone (from the profile). */
  currency: string;
  timezone: string;
}

/**
 * The add/edit sheet for the whole app (the ＋ of the bottom bar, a row on home, "Ponerle
 * nombre" on a toast) and the transaction writes behind it. The writes live here, not in the
 * sheet, so what follows a save (an undo from its toast) still works once the sheet has closed.
 * Each opening is a fresh sheet (its own form and idempotency key).
 */
export function TransactionSheetProvider({
  children,
  currency,
  timezone,
}: TransactionSheetProviderProps) {
  const [sheet, setSheet] = useState<{ open: boolean; request: SheetRequest; session: number }>({
    open: false,
    request: {},
    session: 0,
  });
  const [lastEvent, setLastEvent] = useState<TransactionEvent | null>(null);

  const open = useCallback(
    (request: SheetRequest) =>
      setSheet((current) => ({ open: true, request, session: current.session + 1 })),
    [],
  );
  const openAdd = useCallback(
    (categoryId?: string) => open(categoryId ? { categoryId } : {}),
    [open],
  );
  const openEdit = useCallback(
    (editing: TransactionDto, options: { focusName?: boolean } = {}) =>
      open({ editing, ...(options.focusName ? { focusName: true } : {}) }),
    [open],
  );
  const close = useCallback(() => setSheet((current) => ({ ...current, open: false })), []);
  const report = useCallback(
    (event: Omit<TransactionEvent, "id">) =>
      setLastEvent((current) => ({ ...event, id: (current?.id ?? 0) + 1 })),
    [],
  );

  const [restored, setRestored] = useState<ReadonlySet<string>>(new Set());
  const onRestored = useCallback(
    (id: string) => setRestored((current) => new Set(current).add(id)),
    [],
  );
  useEffect(() => {
    if (restored.size === 0) return;
    const timer = setTimeout(() => setRestored(new Set()), RESTORED_MS);
    return () => clearTimeout(timer);
  }, [restored]);

  const actions = useTransactionActions({ currency, openEdit, report, onRestored });
  const value = useMemo(
    () => ({ openAdd, openEdit, actions, lastEvent, restored }),
    [openAdd, openEdit, actions, lastEvent, restored],
  );

  return (
    <Context.Provider value={value}>
      {children}
      <AddTransactionSheet
        key={sheet.session}
        open={sheet.open}
        onClose={close}
        currency={currency}
        timezone={timezone}
        {...sheet.request}
      />
    </Context.Provider>
  );
}

export function useTransactionSheet(): TransactionSheetContext {
  const value = useContext(Context);
  if (!value) throw new Error("useTransactionSheet needs a <TransactionSheetProvider>");
  return value;
}
