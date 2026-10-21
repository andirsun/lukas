import { monthOf, type TransactionDto } from "@lukas/core";
import {
  keepPreviousData,
  type QueryClient,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { useApi } from "./ApiProvider.tsx";
import { ApiProblem } from "./errors.ts";
import {
  keysFor,
  optimisticAdd,
  optimisticRemove,
  optimisticUpdate,
  type Rollback,
  summaryKey,
  transactionsKey,
} from "./optimistic.ts";
import type { paths } from "./schema";

type JsonBody<
  Path extends keyof paths,
  Method extends keyof paths[Path],
> = paths[Path][Method] extends {
  requestBody?: { content: { "application/json": infer Body } };
}
  ? Body
  : never;

/** The fields to create a transaction with: name, amount (minor units, negative for spending), category, date. */
export type NewTransaction = JsonBody<"/v1/transactions", "post">;
/** The fields to change on a transaction; send only those that changed. */
export type TransactionPatch = JsonBody<"/v1/transactions/{id}", "patch">;
export type ReportRange = { from: string; to: string };

/** The data of a successful response. Failures never get here: the client throws `ApiProblem`. */
function dataOf<T>(result: { data?: T; response: Response }): T {
  if (result.data === undefined) {
    throw new ApiProblem({ status: result.response.status, code: "internal_error" });
  }
  return result.data;
}

export const queryKeys = {
  me: () => ["me"] as const,
  summary: summaryKey,
  transactions: transactionsKey,
  categories: () => ["categories"] as const,
  suggestions: (q: string) => ["suggestions", q] as const,
  recurrences: () => ["recurrences"] as const,
  /** Everything built from transactions beyond one month's list and summary. */
  reports: () => ["reports"] as const,
  costOfLiving: (months: number) => ["reports", "cost-of-living", months] as const,
  byCategory: (range: ReportRange) => ["reports", "by-category", range.from, range.to] as const,
  trend: (range: ReportRange) => ["reports", "trend", range.from, range.to] as const,
};

// -- Reads ------------------------------------------------------------------------------------

export function useMe() {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.me(),
    queryFn: async () => dataOf(await api.GET("/v1/me")),
  });
}

export function useSummary(month: string) {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.summary(month),
    queryFn: async ({ signal }) =>
      dataOf(await api.GET("/v1/summary", { params: { query: { month } }, signal })),
  });
}

/** The month's transactions, newest first. Up to 200 (the API's page limit) in one page. */
export function useTransactions(month: string) {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.transactions(month),
    queryFn: async ({ signal }) =>
      dataOf(
        await api.GET("/v1/transactions", { params: { query: { month, limit: 200 } }, signal }),
      ),
  });
}

export function useCategories() {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.categories(),
    queryFn: async ({ signal }) => dataOf(await api.GET("/v1/categories", { signal })),
  });
}

/** Names you used before, with the category they usually go in, matching what is being typed. */
export function useSuggestions(q: string) {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.suggestions(q),
    queryFn: async ({ signal }) =>
      dataOf(await api.GET("/v1/transactions/suggestions", { params: { query: { q } }, signal })),
    placeholderData: keepPreviousData,
  });
}

export function useRecurrences() {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.recurrences(),
    queryFn: async ({ signal }) => dataOf(await api.GET("/v1/recurrences", { signal })),
  });
}

export function useCostOfLiving(months: number) {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.costOfLiving(months),
    queryFn: async ({ signal }) =>
      dataOf(
        await api.GET("/v1/reports/cost-of-living", { params: { query: { months } }, signal }),
      ),
  });
}

export function useReportByCategory(range: ReportRange) {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.byCategory(range),
    queryFn: async ({ signal }) =>
      dataOf(
        await api.GET("/v1/reports/by-category", {
          params: { query: { from: range.from, to: range.to } },
          signal,
        }),
      ),
  });
}

export function useTrend(range: ReportRange) {
  const api = useApi();
  return useQuery({
    queryKey: queryKeys.trend(range),
    queryFn: async ({ signal }) =>
      dataOf(
        await api.GET("/v1/reports/trend", {
          params: { query: { from: range.from, to: range.to } },
          signal,
        }),
      ),
  });
}

// -- Writes -----------------------------------------------------------------------------------
//
// Each write shows its result at once in the month's list and summary, undoes it if the API says
// no, and refetches either way so the screen ends up showing what the server has.

interface Optimistic {
  rollback: Rollback;
  months: string[];
}

/** Stops in-flight fetches that would overwrite the optimistic change, then applies it. */
async function applyOptimistic(
  qc: QueryClient,
  months: string[],
  apply: () => Rollback,
): Promise<Optimistic> {
  await Promise.all(keysFor(months).map((queryKey) => qc.cancelQueries({ queryKey })));
  return { rollback: apply(), months };
}

function settle(qc: QueryClient, months: string[]) {
  for (const queryKey of keysFor(months)) void qc.invalidateQueries({ queryKey });
  void qc.invalidateQueries({ queryKey: queryKeys.reports() });
}

function mutation<Vars, Result>(
  qc: QueryClient,
  run: (vars: Vars) => Promise<Result>,
  optimistic: (vars: Vars) => { months: string[]; apply: () => Rollback },
) {
  return {
    mutationFn: run,
    onMutate: (vars: Vars) => {
      const { months, apply } = optimistic(vars);
      return applyOptimistic(qc, months, apply);
    },
    onError: (_error: Error, _vars: Vars, context: Optimistic | undefined) => context?.rollback(),
    onSettled: (
      _data: Result | undefined,
      _error: Error | null,
      vars: Vars,
      context: Optimistic | undefined,
    ) => settle(qc, context?.months ?? optimistic(vars).months),
  };
}

/** A stand-in for a transaction the API has not confirmed yet. */
function draftFrom(qc: QueryClient, input: NewTransaction): TransactionDto {
  const now = new Date().toISOString();
  const sibling = qc.getQueryData<{ items: TransactionDto[] }>(
    queryKeys.transactions(monthOf(input.date)),
  )?.items[0];
  return {
    id: `pending-${crypto.randomUUID()}`,
    name: input.name,
    amount: input.amount,
    currency: sibling?.currency ?? "EUR",
    date: input.date,
    status: input.status ?? "paid",
    note: input.note ?? null,
    categoryId: input.categoryId,
    recurrenceId: null,
    importId: null,
    source: input.source ?? "app",
    createdAt: now,
    updatedAt: now,
  };
}

export function useCreateTransaction() {
  const api = useApi();
  const qc = useQueryClient();
  return useMutation(
    mutation(
      qc,
      async (input: NewTransaction) =>
        dataOf(
          await api.POST("/v1/transactions", {
            body: input,
            // A retry of this same request (a flaky connection) must not book it twice.
            headers: { "Idempotency-Key": crypto.randomUUID() },
          }),
        ),
      (input) => ({
        months: [monthOf(input.date)],
        apply: () => optimisticAdd(qc, draftFrom(qc, input)),
      }),
    ),
  );
}

/** `month` is the month of the list the transaction is shown in; `patch.date` may move it elsewhere. */
export interface UpdateTransactionVars {
  id: string;
  month: string;
  patch: TransactionPatch;
}

export function useUpdateTransaction() {
  const api = useApi();
  const qc = useQueryClient();
  return useMutation(
    mutation(
      qc,
      async ({ id, patch }: UpdateTransactionVars) =>
        dataOf(await api.PATCH("/v1/transactions/{id}", { params: { path: { id } }, body: patch })),
      ({ id, month, patch }) => ({
        months: patch.date ? [month, monthOf(patch.date)] : [month],
        apply: () => optimisticUpdate(qc, month, id, patch),
      }),
    ),
  );
}

export interface TransactionRef {
  id: string;
  month: string;
}

/** Deleting is undoable: the API keeps the transaction, and `useRestoreTransaction` brings it back. */
export function useDeleteTransaction() {
  const api = useApi();
  const qc = useQueryClient();
  return useMutation(
    mutation(
      qc,
      async ({ id }: TransactionRef) => {
        await api.DELETE("/v1/transactions/{id}", { params: { path: { id } } });
      },
      ({ id, month }) => ({ months: [month], apply: () => optimisticRemove(qc, month, id) }),
    ),
  );
}

/** Pass the transaction being brought back (the screen has it from the delete); it reappears at once. */
export function useRestoreTransaction() {
  const api = useApi();
  const qc = useQueryClient();
  return useMutation(
    mutation(
      qc,
      async ({ transaction }: { transaction: TransactionDto }) =>
        dataOf(
          await api.POST("/v1/transactions/{id}/restore", {
            params: { path: { id: transaction.id } },
          }),
        ),
      ({ transaction }) => ({
        months: [monthOf(transaction.date)],
        apply: () => optimisticAdd(qc, transaction),
      }),
    ),
  );
}

/** Marks a pending transaction paid. */
export function useMarkPaid() {
  const api = useApi();
  const qc = useQueryClient();
  return useMutation(
    mutation(
      qc,
      async ({ id }: TransactionRef) =>
        dataOf(
          await api.PATCH("/v1/transactions/{id}", {
            params: { path: { id } },
            body: { status: "paid" },
          }),
        ),
      ({ id, month }) => ({
        months: [month],
        apply: () => optimisticUpdate(qc, month, id, { status: "paid" }),
      }),
    ),
  );
}
