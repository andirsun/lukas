# PendingBadge

Marks a transaction that is scheduled but not paid yet (recurring charges, future dates). It is also the button that pays it: tapping it sends `PATCH /v1/transactions/:id { status: "paid" }`, plays the `paid` feedback and turns into `✓ Pagado` for a moment.

- Text is `Pendiente` / `Pending`, uppercase `overline`-like; color `near`.
- Use it only on pending transactions; never as decoration.
