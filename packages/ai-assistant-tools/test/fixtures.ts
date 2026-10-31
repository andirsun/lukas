import type { CategoryDto, TransactionDto } from "@lukas/core";

let counter = 0;
/** A deterministic, valid v4-shaped uuid, so tests can name ids. */
export function uuid(n = ++counter): string {
  return `00000000-0000-4000-8000-${String(n).padStart(12, "0")}`;
}

export function category(
  name: string,
  kind: "expense" | "income" = "expense",
  extra: Partial<CategoryDto> = {},
): CategoryDto {
  return {
    id: uuid(),
    name,
    kind,
    icon: "🏷️",
    color: "#8e87b8",
    sortOrder: 0,
    archived: false,
    currentBudget: null,
    ...extra,
  };
}

export function transaction(
  cat: CategoryDto,
  amount: number,
  date: string,
  extra: Partial<TransactionDto> = {},
): TransactionDto {
  const stamp = `${date}T12:00:00.000Z`;
  return {
    id: uuid(),
    name: cat.name,
    amount,
    currency: "COP",
    date,
    status: "paid",
    note: null,
    categoryId: cat.id,
    recurrenceId: null,
    importId: null,
    source: "app",
    createdAt: stamp,
    updatedAt: stamp,
    ...extra,
  };
}
