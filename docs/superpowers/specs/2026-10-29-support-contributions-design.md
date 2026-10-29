# Lukitas — Support contributions ("Apoya a Lukitas")

- **Date:** 2026-10-29
- **Status:** draft for review. A plan for later: nothing here is built yet.
- **Founder decisions (2026-10-29):**
  1. Lukitas stays free forever. A contribution never unlocks a feature.
  2. Contributions go to **Slinqer S.A.S.**, the company that maintains Lukitas.
  3. Both one-time and monthly contributions.
  4. A contribution is tied to the Lukitas account when the person is signed in.
  5. **Wompi** is the only payment gateway in Colombia.
  6. People abroad can contribute too: by card through Wompi, and through GitHub Sponsors.
  7. The Android app ships both on Google Play and outside it (APK / F-Droid).
- **Reviewed with the founder:** §2 (the experience). §3 to §6 were written afterwards and still
  need the founder's review.

## 1. Goal

Anyone who finds Lukitas useful can help pay for it in under a minute, from Colombia or abroad, once
or every month. The money reaches Slinqer S.A.S.'s account, the person sees that they support Lukitas,
and a monthly contribution can be cancelled with one tap.

This is the first step of the business model:
- free forever for everything that costs the project nothing per person;
- contributions now;
- later, a paid plan only for features with a real cost per person (AI capture beyond the quota,
  WhatsApp, bank connections, server-side transcription), and work with organizations.

### Out of scope

- Any feature behind a contribution.
- Google Play Billing (see §4.3).
- Linking a GitHub sponsor to a Lukitas account.
- PayPal, Ko-fi, Open Collective, Liberapay: two channels are enough to start, and each one more is
  one more account to reconcile.
- Rewards. Stage 5 (gamification) may add cosmetic ones for supporters; this spec only records who
  supports.

## 2. The experience

### 2.1 Where it appears

| Where | What |
|---|---|
| Public web | A page `/apoyar`, with `/en/support`, `/it/sostieni` and `/pt/apoiar` like the roadmap pages |
| Web app | A row "Apoya a Lukitas" in Ajustes, which opens `/apoyar` |
| Android, outside Play | The same row in Ajustes, which opens `/apoyar` in the browser with the session (§4.2) |
| Android, Google Play | No row, no link, no mention of paying (§4.3) |
| Repository | `.github/FUNDING.yml` with `github: slinqer`, which shows GitHub's "Sponsor" button |

`/apoyar` says:
- what Lukitas is and that it is free forever;
- what it costs to run, and that contributions pay for it;
- "N personas apoyan este mes" (§3.4);
- the form (§2.2);
- "¿Prefieres en dólares? GitHub Sponsors", with the public GitHub sponsors listed.

### 2.2 Contributing

1. Choose **una vez** or **cada mes**.
2. Choose an amount: three suggested ones ($5.000, $10.000, $20.000 COP) or a free one, with a
   minimum of $5.000. Amounts are always in COP.
   - On the `en`, `it` and `pt` pages, every amount shows a rough equivalent: "$20.000 COP ≈ 5 USD"
     (EUR on `it` and `pt`). The rate is a constant updated by hand; the copy says "≈".
3. Pay through Wompi:
   - **Una vez:** Nequi, PSE, card, Botón Bancolombia.
   - **Cada mes:** Nequi, card, Botón Bancolombia. PSE is not offered: it cannot be charged again.
   - Abroad, only cards work.
4. Back on `/apoyar`: "¡Gracias!" once the payment is approved, or what went wrong.

Signed in, the contribution is tied to the account. Signed out (or a guest), it is anonymous: nobody
has to make an account to give money.

### 2.3 What a contribution gives

- A quiet "Apoyas a Lukitas" in Ajustes, and "desde octubre de 2026".
- Never a feature.

### 2.4 Monthly contributions

- Ajustes shows "Apoyas con $10.000 cada mes · próximo cobro el 12 de nov." and **Cancelar**.
- Cancelar works in one tap: no questions, no "are you sure you want to leave us". The charge stops
  that same moment; what was already paid is not refunded.
- A failed charge is tried again 3 times over a week (day 1, 3 and 7). After the third failure the
  contribution is cancelled and the person gets an email with a link to start it again.
- The person can change the amount by cancelling and starting a new one. No "change amount" flow at
  first.

### 2.5 Words

- "Apoya a Lukitas", "aporte", "apoyar". Never "donación" (§5).
- Under every pay button: *"Lo recibe Slinqer S.A.S., la empresa que mantiene Lukitas. No es una
  donación deducible de impuestos."*
- All four languages, in Lukitas' voice, through the existing catalogs and their parity tests.

## 3. Server

Everything goes through the API, as the rest of Lukitas does. The web page and the app never talk to
Wompi with a private key.

### 3.1 Tables

```
support_payments                       -- one row per Wompi transaction
  id               uuid pk
  user_id          uuid null           -- null: anonymous
  plan_id          uuid null           -- the monthly plan it charged, if any
  reference        text unique         -- ours, sent to Wompi; ties the event back to the row
  wompi_id         text unique null    -- Wompi's transaction id, once known
  amount_cents     bigint not null     -- COP, in cents as Wompi counts them
  method           text not null       -- NEQUI | PSE | CARD | BANCOLOMBIA_TRANSFER
  status           text not null       -- PENDING | APPROVED | DECLINED | VOIDED | ERROR
  created_at, updated_at

support_plans                          -- a monthly contribution
  id               uuid pk
  user_id          uuid null           -- null: an anonymous monthly contribution (email only)
  email            text not null       -- for the receipt and the "your charge failed" email
  amount_cents     bigint not null
  payment_source_id bigint not null    -- Wompi's saved Nequi / card / Bancolombia source
  method           text not null
  status           text not null       -- ACTIVE | CANCELLED
  next_charge_on   date not null
  failed_attempts  int not null default 0
  cancelled_at     timestamptz null
  created_at, updated_at
```

- No card number, phone number or account number is ever stored: only Wompi's ids.
- RLS like the other tables: a person reads only their own rows. The webhook and the monthly job
  write as the API's service role.
- "Apoyas a Lukitas" (§2.3) is: an `APPROVED` payment in the last 31 days, or an `ACTIVE` plan.
  `GET /v1/me` gets `supporter: { since, plan: { amount, nextChargeOn } | null } | null`.

### 3.2 Endpoints

| Endpoint | What it does |
|---|---|
| `POST /v1/support/checkout` | One-time. Creates a `PENDING` payment with a new `reference` and returns what Wompi's checkout needs: public key, amount, reference, integrity signature, redirect URL. Works without a session. |
| `POST /v1/support/plans` | Monthly. Takes the Wompi token the page made with the public key (card, Nequi or Bancolombia), creates the payment source with the private key, charges the first month, and creates the plan. |
| `DELETE /v1/support/plans/:id` | Cancels. Needs the session, or the signed link from the email for an anonymous plan. |
| `POST /v1/support/wompi/events` | Wompi's webhook (§3.3). Not under the session. |
| `GET /v1/support/count` | "N personas apoyan este mes", for `/apoyar`. Public, cached for an hour. |

The integrity signature and the private key stay on the server. Amounts are checked on the server
(minimum, maximum, whole pesos) whatever the page sends.

### 3.3 The webhook

- Verify every event: SHA-256 of the values Wompi lists in `signature.properties`, then
  `timestamp`, then the events secret, compared with `X-Event-Checksum`. A wrong checksum is
  ignored (and logged without the body).
- Read `signature.properties` from each event; Wompi says the list can change.
- `transaction.updated` finds the row by `reference` and sets `status` and `wompi_id`.
  - Applying the same event twice changes nothing: the update is by reference and to a final status.
  - A final status never goes back to `PENDING`.
- `nequi_token.updated` and `bancolombia_transfer_token.updated` move a monthly plan waiting for
  the person's approval forward (§3.2 waits for `APPROVED` before creating the source).
- Always answer `200` once the event is stored, even if nothing matched: Wompi retries anything
  else 3 times over 24 hours.
- One events URL for sandbox and one for production, as Wompi recommends.

### 3.4 The monthly job

A daily job in the API process, scheduled like `scheduleGuestCleanup`
(`apps/api/src/services/guest-cleanup.ts`):

1. Take the `ACTIVE` plans with `next_charge_on <= today`.
2. For each, create a payment with a new `reference` and charge its `payment_source_id` with the
   private key (`recurrent: true` for Visa and Mastercard cards, which Wompi needs for card-on-file).
3. The webhook settles it:
   - **Approved:** `next_charge_on` moves one month and `failed_attempts` goes to 0.
   - **Declined or error:** `failed_attempts` goes up and `next_charge_on` moves to the next try
     (day 3, then day 7). At the third failure the plan is `CANCELLED` and the email goes out.
4. A plan never gets two charges for the same month: the reference is
   `plan:<id>:<yyyy-mm>:<attempt>`, and the job skips a plan with a `PENDING` payment.

"N personas apoyan este mes" counts distinct people (or anonymous payments) with an `APPROVED`
payment in the current calendar month. GitHub sponsors are not in the count: `/apoyar` lists them
apart, from GitHub's public sponsors list.

### 3.5 Configuration

New env vars, all optional: without them `/apoyar` shows only the GitHub Sponsors link, so a
self-hosted install or the personal install works without a Wompi account.

- `WOMPI_PUBLIC_KEY`, `WOMPI_PRIVATE_KEY`, `WOMPI_INTEGRITY_SECRET`, `WOMPI_EVENTS_SECRET`
- `WOMPI_ENV` (`sandbox` | `production`)
- `SUPPORT_RATES` (the rough COP → USD and COP → EUR rates for §2.2)

The Caddyfile serves `/api/v1/support/wompi/events` on the internet like the rest of `/api`.

## 4. Clients

### 4.1 Web

- `/apoyar` and its three translations: public, no session needed, using the session when there is
  one.
- Wompi's checkout (widget or redirect) for one-time; Wompi's tokenization with the public key for
  monthly, then `POST /v1/support/plans`.
- Ajustes: the supporter line, the monthly plan and Cancelar.

### 4.2 Android, outside Play

- The row opens `/apoyar` in the browser. The session goes along as a short-lived, single-use code
  in the URL that the web exchanges for its session. Never the bearer token itself.
- Ajustes shows the supporter line and the plan from `GET /v1/me`. Cancelar calls the API directly.

### 4.3 Android on Google Play

Being recognized in the app as a supporter is likely a digital good to Google Play, which then asks
for Google Play Billing and forbids linking to another way to pay. So the Play build shows nothing
about contributing:

- A build-time flag, `--dart-define=LUKITAS_CHANNEL=direct`, turns the row on. **Without it the row
  is off**, so a Play build can never show it by mistake. The APK / F-Droid build passes the flag.
- The supporter line itself (§2.3) may still show in the Play build for someone who contributed
  on the web. Check this against the policy too.
- **Before building:** check the current Google Play payments policy. If it allows it by then, a
  plain link may be possible.

### 4.4 The widget

Nothing changes.

## 5. Legal and money (to confirm with the accountant)

Not legal advice: these are the questions to settle before turning it on.

- Slinqer S.A.S. is a for-profit company. Money it receives is **income**, not a deductible
  donation, hence "aporte" and the line under the button (§2.5).
- It probably needs an **electronic invoice** (factura electrónica) per contribution, or a monthly
  arrangement the DIAN accepts for small amounts. Decide how before launch; it may need the
  invoicing provider to be told about each approved payment.
- Money from abroad (cards through Wompi, GitHub Sponsors in USD) has **exchange rules**
  (régimen cambiario) and may count as an **export of services** for IVA.
- Open the Wompi account and the GitHub Sponsors profile for `slinqer` in Slinqer's name.
- Confirm with Wompi that cards issued abroad are accepted for this account, and its current fees.
- **Privacy policy:** add that contributions are processed by Wompi (and GitHub for sponsors), that
  Lukitas keeps only amounts, dates, status and Wompi's ids, and who the data controller is
  (Slinqer S.A.S.).
- **Terms:** add a short section: what a contribution is, that it unlocks nothing, how to cancel,
  and that paid months are not refunded.

## 6. Testing

- **Unit:** the webhook checksum (good, bad, a changed `signature.properties` list); the amount
  checks; the monthly job's dates and retries (day 1, 3, 7, then cancelled); the "supporter" rule.
- **API:** against Wompi's sandbox with its test cards and Nequi numbers, in CI only where the
  sandbox keys are available. The same event applied twice; an event for an unknown reference.
- **Web:** `/apoyar` in four languages, signed in and out; the catalog parity tests.
- **Android:** the row hidden without `LUKITAS_CHANNEL=direct`, shown with it.
- **By hand before launch:** one real contribution of each kind on production, cancelled and
  refunded from Wompi's dashboard.

## 7. Order, when it is built

1. Legal and accounts (§5): Wompi account, invoicing, GitHub Sponsors. Nothing ships before.
2. `.github/FUNDING.yml` and a static `/apoyar` with only GitHub Sponsors. This can go first: it
   needs no server work.
3. Tables, endpoints and webhook; one-time contributions on the web.
4. Monthly contributions and the job.
5. Ajustes in the web and the Android (direct) app.
6. Privacy policy and terms updated in the same release as step 3.

## 8. Risks

- **Play policy:** a mistake here can get the app pulled from Play. The flag is off by default.
- **Invoicing:** if every $5.000 contribution needs a hand-made invoice, the cost eats the
  contribution. Settle §5 first.
- **Failed monthly charges:** Nequi needs the person to approve a subscription in their app, and
  cards expire. The retry and the email cover it; a rising failure rate is a sign to look at.
- **Webhook missed:** Wompi retries for 24 hours only. A daily check asks Wompi for any payment
  still `PENDING` after a day and settles it.
- **Encryption later:** contribution data is not financial data the person enters, and the server
  needs it to charge. It stays readable to the server when end-to-end encryption arrives.
