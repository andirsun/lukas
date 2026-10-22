/**
 * The shared schemas, named for the OpenAPI document: each becomes a component
 * (`#/components/schemas/<Name>`) that operations reference, so generated clients get these names
 * instead of ones derived from paths. The schemas themselves live in @lukas/core and are built
 * with plain zod, possibly before @hono/zod-openapi has added `.openapi()` to zod, so they are
 * named with zod's own `.meta({ id })`, which the document generator reads the same way. It
 * returns a named copy and leaves the core schemas unchanged. Schemas declared in the routes, with
 * @hono/zod-openapi's `z`, use `.openapi(name)`.
 */
import { z } from "@hono/zod-openapi";
import {
  categoryDto,
  createCategorySchema,
  createRecurrenceSchema,
  createTransactionSchema,
  createTransactionsBatchSchema,
  deleteTransactionsBatchSchema,
  monthSummaryDto,
  problemDto,
  recurrenceDto,
  setBudgetSchema,
  transactionDto,
  updateCategorySchema,
  updateProfileSchema,
  updateRecurrenceSchema,
  updateTransactionSchema,
} from "@lukas/core";

export const Problem = problemDto.meta({ id: "Problem" });

export const Transaction = transactionDto.meta({ id: "Transaction" });
export const CreateTransaction = createTransactionSchema.meta({ id: "CreateTransaction" });
export const UpdateTransaction = updateTransactionSchema.meta({ id: "UpdateTransaction" });
export const CreateTransactionsBatch = createTransactionsBatchSchema.meta({
  id: "CreateTransactionsBatch",
});
export const DeleteTransactionsBatch = deleteTransactionsBatchSchema.meta({
  id: "DeleteTransactionsBatch",
});

export const Category = categoryDto.meta({ id: "Category" });
export const CreateCategory = createCategorySchema.meta({ id: "CreateCategory" });
export const UpdateCategory = updateCategorySchema.meta({ id: "UpdateCategory" });
export const SetBudget = setBudgetSchema.meta({ id: "SetBudget" });

export const Recurrence = recurrenceDto.meta({ id: "Recurrence" });
export const CreateRecurrence = createRecurrenceSchema.meta({ id: "CreateRecurrence" });
export const UpdateRecurrence = updateRecurrenceSchema.meta({ id: "UpdateRecurrence" });

export const Summary = monthSummaryDto.meta({ id: "Summary" });
export const UpdateProfile = updateProfileSchema.meta({ id: "UpdateProfile" });

/**
 * The `Idempotency-Key` request header (src/http/idempotency.ts): a retry with the same key and
 * body replays the first response. Header names are matched without regard to case.
 */
export const idempotencyKeyHeader = ({ required }: { required: boolean }) =>
  z.object({
    "Idempotency-Key": (required ? z.string().min(1) : z.string().optional()).openapi({
      description:
        "A key that stays the same across retries of the same request (a UUID, say): a retry with the same key and body returns the first response instead of saving twice.",
    }),
  });
