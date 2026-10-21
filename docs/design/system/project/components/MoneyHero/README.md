# MoneyHero

The hero card with what is left to spend this month (`amount-hero` in `good`), a bar that fills with what was spent, and the spent/budget line under it.

- Consumer provides: `remaining`, `spent`, `budgetTotal` (cents, from `GET /v1/summary`) and the locale.
- After a save the amount counts to its new value over `count-up` (700ms).
- Exactly one per screen. If `remaining` is negative, show `Te pasaste X` in `over` instead of a negative number.
