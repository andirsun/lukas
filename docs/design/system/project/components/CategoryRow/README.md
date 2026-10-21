# CategoryRow

One expense category in the budget list: glyph tile, name, monthly budget, status line in words and a small `BudgetBar`.

- Consumer provides: category (name, glyph, tint), `budget`, `spent`, `remaining`, `state`.
- The whole row is pressable and opens the category detail.
- Order follows the person's `sortOrder`; categories without a budget show `Sin presupuesto` and no bar.
