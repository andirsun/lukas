// The author's October 2026 Budge screenshots, with budgets adjusted to sum exactly 2,800.00 €.
// Shared by core and api tests.
export const OCTOBER_2026 = {
  month: "2026-10",
  expense: [
    { key: "supermercado", name: "Supermercado", budget: 18000, spent: 19412 },
    { key: "restaurante", name: "Restaurante", budget: 30000, spent: 25367 },
    { key: "ocio", name: "Ocio", budget: 65000, spent: 26280 },
    { key: "casa", name: "Casa", budget: 135000, spent: 132978 },
    { key: "transporte", name: "Transporte", budget: 9000, spent: 0 },
    { key: "suscripciones", name: "suscripciones", budget: 3000, spent: 3689 },
    { key: "vida", name: "Vida", budget: 14000, spent: 9832 },
    { key: "taxes", name: "Taxes", budget: 6000, spent: 6150 },
  ],
  income: [{ key: "salario", name: "Salário", received: 620000 }],
} as const;
