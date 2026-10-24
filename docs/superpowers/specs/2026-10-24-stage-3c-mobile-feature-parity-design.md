# Lukitas — Stage 3c: everything the web does, the app does

- **Date:** 2026-10-24
- **Status:** draft for review
- **Builds on:**
  - `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md` (Stage 3);
  - `docs/superpowers/specs/2026-10-23-stage-3b-mobile-parity-design.md` (3b: the app looks like the web).
  This spec widens Stage 3's scope A. Where they differ, this one wins.
- **Why:** after trying the app, the founder decided on 2026-10-24: "Que todo se pueda hacer en la app igual que en la web." ("Everything should be doable in the app, the same as on the web.")

## 1. Goal

A signed-in person can do everything in the app that the web app lets them do, with the same screens, copy, rules and look. The web stays the reference. Each new screen is ported from the web's code and checked against its Storybook story with the 3b parity harness (`docs/mobile/parity.md`).

The landing, the roadmap and the demo stay web-only. They are for people without an account.

## 2. What the app gains

| Area | Web source | What it does |
|---|---|---|
| **Categories** | `features/categories/CategoriesPage.tsx`, `CategoryForm.tsx`, `use-category-sheets.tsx` | List, create, rename, choose the icon and colour, archive and unarchive. The category detail and budget sheet already exist from 3b. |
| **Recurring payments** | `features/recurring/RecurringPage.tsx`, `RecurringForm.tsx`, `recurring-model.ts` | List, create, edit and end recurring payments, with the same rules and model tests. |
| **Import** | `features/onboarding/ImportPage.tsx`, `ImportStep.tsx`, `use-import-flow.ts`, `import-state.ts` | Pick a file (Android's own file picker, the Storage Access Framework, so no Google), preview, confirm. The same `/v1/imports` flow and rules, including currency on an empty account and budgets prefilled after import. |
| **Welcome (onboarding)** | `features/onboarding/Welcome.tsx` and steps: `WelcomeStep`, `CurrencyStep`, `CategoriesStep`, `BudgetsStep`, `ImportStep`; `steps.ts`, `onboarding-draft.ts` | The same steps and order, shown when the web would show them (`onboardingCompletedAt`). This replaces Stage 3's "email users get the device's zone and currency" stopgap with the real choice. Guests keep their guest start. |
| **Settings: time zone and currency** | `features/settings/TimeAndMoneySection.tsx` | Same rules, including the currency lock after the first movement. |
| **Settings: passkeys** | `features/settings/PasskeysSection.tsx`, `passkeys.ts` | List, add, rename (if the web does) and delete. |
| **Settings: export** | `features/settings/use-export.ts` | JSON or CSV, as the web offers. The file is handed to Android's share sheet or saved with the Storage Access Framework. |
| **Settings: delete account** | `features/settings/DeleteAccount.tsx` | Same flow: type the account's email to unlock "Borrar mi cuenta", then `DELETE /v1/me`, sign out, and land on entry. The app's local data (cache, widget snapshot, notices, voice model) is cleared too. |
| **Navigation** | `features/home/AppShell.tsx`, the face menu, `routes.ts` | Every page above is reachable the way the web reaches it. "Más en la web" stays only for what is truly web-only. |

## 3. Rules that carry over

- 3b's global constraints: the web is the reference; parity is under 2% of ink at 412 × 915 in night and day; copy goes in ARB; no Google.
- Stage 3's behaviour rules still apply:
  - idempotency keys on every create;
  - month guards;
  - the offline cache covers the current month only;
  - the widget and notices stay in step after any change that affects them, such as archiving a category with a budget, ending a recurring payment, or deleting the account.
- **Permissions:** the file picker and share sheet need none. `check-permissions.sh` stays unchanged.
- **Guests:**
  - **Allowed, as on the web:** import, recurring payments and categories.
  - **Need an email, as on the web:** export and delete account. Settings shows them the way the web does for a guest.

## 4. Testing

- Parity pairs for each new screen's stories, in night and day.
- The web's model tests ported one for one, for recurring, import and onboarding.
- Emulator tests against the dev stack for:
  - creating a category;
  - creating and ending a recurring payment;
  - importing a fixture CSV through the picker;
  - completing onboarding as a new email user;
  - exporting;
  - deleting a throwaway account.

## 5. Risks

- **Size:** about as large as 3b, so roughly 12 to 16 hours of work.
- **The Android file picker** can't be driven fully in emulator tests. The import test injects the file through the same platform channel the picker uses.
- **Delete account** is destructive. It is tested only on throwaway dev-stack accounts, never against the personal install.
