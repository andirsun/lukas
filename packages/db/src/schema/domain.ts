import { sql } from "drizzle-orm";
import {
  bigint,
  boolean,
  char,
  date,
  index,
  integer,
  jsonb,
  pgEnum,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";
import { v7 as uuidv7 } from "uuid";
import { user } from "./auth.ts";

const id = () =>
  uuid("id")
    .primaryKey()
    .$defaultFn(() => uuidv7());
const userId = () =>
  text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" });
const money = (name: string) => bigint(name, { mode: "number" });
const timestamps = {
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
};

export const categoryKind = pgEnum("category_kind", ["expense", "income"]);
export const transactionStatus = pgEnum("transaction_status", ["paid", "pending"]);
export const transactionSource = pgEnum("transaction_source", [
  "app",
  "web",
  "widget",
  "mcp",
  "import",
  "recurrence",
]);
export const recurrenceFrequency = pgEnum("recurrence_frequency", ["monthly", "yearly"]);
export const importSource = pgEnum("import_source", ["budge"]);
export const importStatus = pgEnum("import_status", ["preview", "confirmed", "reverted"]);

export const accounts = pgTable(
  "accounts",
  {
    id: id(),
    userId: userId(),
    name: text("name").notNull(),
    currency: char("currency", { length: 3 }).notNull(),
    isDefault: boolean("is_default").notNull().default(false),
    ...timestamps,
  },
  (t) => [uniqueIndex("accounts_one_default").on(t.userId).where(sql`${t.isDefault}`)],
);

export const categories = pgTable(
  "categories",
  {
    id: id(),
    userId: userId(),
    name: text("name").notNull(),
    kind: categoryKind("kind").notNull(),
    icon: text("icon").notNull(),
    color: text("color").notNull(),
    sortOrder: integer("sort_order").notNull().default(0),
    archivedAt: timestamp("archived_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [
    uniqueIndex("categories_active_name")
      .on(t.userId, sql`lower(${t.name})`)
      .where(sql`${t.archivedAt} is null`),
  ],
);

export const categoryBudgets = pgTable(
  "category_budgets",
  {
    id: id(),
    userId: userId(),
    categoryId: uuid("category_id")
      .notNull()
      .references(() => categories.id, { onDelete: "cascade" }),
    amount: money("amount").notNull(),
    effectiveFrom: date("effective_from").notNull(),
    ...timestamps,
  },
  (t) => [uniqueIndex("category_budgets_month").on(t.categoryId, t.effectiveFrom)],
);

export const recurrences = pgTable("recurrences", {
  id: id(),
  userId: userId(),
  accountId: uuid("account_id")
    .notNull()
    .references(() => accounts.id, { onDelete: "cascade" }),
  categoryId: uuid("category_id")
    .notNull()
    .references(() => categories.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  amount: money("amount").notNull(),
  frequency: recurrenceFrequency("frequency").notNull(),
  dayOfMonth: integer("day_of_month").notNull(),
  monthOfYear: integer("month_of_year"),
  startDate: date("start_date").notNull(),
  endDate: date("end_date"),
  ...timestamps,
});

export const imports = pgTable("imports", {
  id: id(),
  userId: userId(),
  source: importSource("source").notNull(),
  fileHash: text("file_hash").notNull(),
  status: importStatus("status").notNull().default("preview"),
  stats: jsonb("stats").notNull(),
  payload: jsonb("payload"),
  ...timestamps,
});

export const transactions = pgTable(
  "transactions",
  {
    id: id(),
    userId: userId(),
    accountId: uuid("account_id")
      .notNull()
      .references(() => accounts.id, { onDelete: "cascade" }),
    categoryId: uuid("category_id")
      .notNull()
      .references(() => categories.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    amount: money("amount").notNull(),
    currency: char("currency", { length: 3 }).notNull(),
    date: date("date").notNull(),
    status: transactionStatus("status").notNull().default("paid"),
    note: text("note"),
    recurrenceId: uuid("recurrence_id").references(() => recurrences.id, { onDelete: "set null" }),
    importId: uuid("import_id").references(() => imports.id, { onDelete: "set null" }),
    source: transactionSource("source").notNull(),
    externalHash: text("external_hash"),
    deletedAt: timestamp("deleted_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [
    index("transactions_user_date").on(t.userId, t.date),
    index("transactions_user_category_date").on(t.userId, t.categoryId, t.date),
    uniqueIndex("transactions_recurrence_date")
      .on(t.recurrenceId, t.date)
      .where(sql`${t.recurrenceId} is not null`),
    uniqueIndex("transactions_external_hash").on(t.userId, t.externalHash),
  ],
);

export const idempotencyKeys = pgTable(
  "idempotency_keys",
  {
    userId: userId(),
    key: text("key").notNull(),
    requestHash: text("request_hash").notNull(),
    status: integer("status").notNull(),
    body: jsonb("body").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.key] })],
);

/** Per-email throttle for sign-in emails. Not user-scoped, so no RLS. */
export const emailThrottle = pgTable("email_throttle", {
  email: text("email").primaryKey(),
  windowStart: timestamp("window_start", { withTimezone: true }).notNull(),
  count: integer("count").notNull(),
});

/** Tables protected by row-level security on `user_id`. */
export const RLS_TABLES = [
  "accounts",
  "categories",
  "category_budgets",
  "recurrences",
  "imports",
  "transactions",
  "idempotency_keys",
] as const;
