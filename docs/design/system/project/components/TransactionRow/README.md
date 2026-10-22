# TransactionRow

One transaction: glyph of its category, name (or the category name when it has none), category, amount in `amount-row`. Rows are grouped under an `overline` day header with the day's total.

- Pending transactions carry a `PendingBadge` after the category.
- The row is pressable and opens the edit sheet. Expenses use a real minus sign; income shows `+` and `good`.
