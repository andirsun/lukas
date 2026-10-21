# BudgetBar

A track that **fills with what was spent** (never with what is left) and changes color by state: `good` below 80 %, `near` from 80 %, `over` above 100 % (capped at full).

- Classes: `lk-bar` (12px) or `lk-bar lk-bar-sm` (7px, inside rows); state `is-near` / `is-over`; the fill is the inner `span` with an inline width.
- The state comes from `MonthSummary.categories[].state`; never recompute it in the client.
- Always pair it with a status line in words; the color alone never carries the meaning.
