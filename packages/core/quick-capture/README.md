# Quick-capture parser cases

Shared test cases for the on-device sentence parser (spec section 5, `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md`). The Dart parser in `apps/mobile` runs every case. A future TypeScript parser on the web runs the same file.

- `cases.json`: the cases (a JSON array).
- `cases.schema.json`: JSON Schema (2020-12) for that file.
- `../src/quick-capture-cases.test.ts`: validates the file against the schema and checks it is consistent (category rules, dates, the Review Focus cases). It does not run a parser.

## A case

```json
{
  "id": "spike-s02",
  "input": "gasté 15 mil en almuerzo y 3 lukas en uber",
  "locale": "es",
  "currency": "COP",
  "today": "2026-10-22",
  "timeZone": "America/Bogota",
  "categories": [{ "id": "cat-comida", "name": "Comida", "kind": "expense" }],
  "usual": [{ "name": "almuerzo", "categoryId": "cat-comida" }],
  "expected": {
    "drafts": [
      { "amount": 1500000, "kind": "expense", "name": "almuerzo", "categoryId": "cat-comida", "date": "2026-10-22" }
    ],
    "unread": []
  }
}
```

A parser passes a case when, for the given inputs, it returns exactly `expected.drafts` (same order) and exactly `expected.unread` (same order).

- **`amount`** is integer cents, x100 for every currency: 15 mil COP is `1500000`, 9,50 EUR is `950`.
- **`today`** is already the date in `timeZone`. The parser never reads the clock and never shifts the date by the time zone; `timeZone` says where `today` was computed.
- **`usual`** is the `GET /v1/transactions/suggestions` shape: name to usual category.
- **`unread`** holds the fragments as heard (original case and spelling, without the connector that separated them).

## Conventions the cases pin

The spec leaves these open, and the expected values rely on them. If the parser needs to change one, change it here too.

- **Names**
  - Lowercase, in the spoken spelling (accents kept: `éxito`, `café`).
  - Dropped: the verb, the amount (with its currency word, like "euros" or "dollars"), the date word, and the function words `en de para por on for` plus the articles `el la los las un una the a an`.
  - Everything else stays, in order, so a misheard word stays in the name (`este almuerzo`, `rapid`).
  - What remains can be empty: `""`.
  - **"A name"** (in the rules below) is any word that is not an amount word, a date word, a function word or the verb. A misheard verb is therefore a name: `gastos` in `gastos de mil` is one, and so is `spend` (the verb is `spent`).
- **Where a name sits:** before the amount (`uber siete mil`), after it (`gasté 8 mil en taxi`) or around it (`pagué el arriendo, un millón`).
- **Splitting**
  - A connector (`y`, `and`, `,`, `también`, `also`) starts a new movement only when the movement so far has an amount and the text after the connector has an amount. So `pan y leche 8 mil`, `gasté 8 mil en pan y leche` and `spent 12 on bread and milk` are one movement.
  - A decimal comma (`9,50`) or a thousands comma (`1,200`) is not a connector.
  - `y` inside a number word (`treinta y cinco mil`) is not a connector. In `siete mil quinientos y cinco mil`, `quinientos y cinco` is not a number, so the `y` splits.
  - **No connector:** an amount that follows a movement already holding an amount and a name starts a new movement, even with no connector. The words between the two amounts (the middle) go to the earlier movement if it has no name before its amount (`gasté doce mil en taxi cuarenta mil en mercado`: `en taxi` is the first movement's). They go to the later movement if the earlier one already has a name before its amount (`taxi doce mil mercado cuarenta mil`: `mercado` is the second movement's). Words after the last amount stay with the last movement.
  - **Same amount:** number words with no name between them are one amount when they form a valid number (`mil quinientos` is 1.500, `veintidós mil novecientos` is 22.900). They are not two movements.
  - **No name at all:** two amounts with no name anywhere in the movement and that do not form one valid number (`gasté 12 mil 40 mil`) are not split, because the first movement holds no name, and not merged. The whole movement is unread (`unread: ["gasté 12 mil 40 mil"]`).
- **Number forms:**
  - es: a dot followed by exactly three digits is thousands (`15.000`, `1.500.000`), a comma is the decimal (`9,50`, `4,3 palos`). A space before exactly three digits is thousands too (`120 000`; Whisper writes that).
  - en: a comma is thousands, a dot is the decimal.
  - `k` after digits is x1.000, in any currency. `mil`, `millón` and `millones` work with digits and with words.
  - Bare `mil` is 1.000 (`gasté mil en chicle`, and the `mil` left by a misheard `doce` in `gastos de mil`).
  - **Scale words** are `mil`, `millón`/`millones`, `thousand`, `million`, and the COP slang units `palo(s)` and `luca(s)`/`lukas`.
  - `con` joins units and cents (`nueve con cincuenta`, `9 euros con 50`).
  - Number words may come without accents (`veintidos`, `dieciseis`).
  - `un` and `una` are numbers only before a scale word (see above: `un millón`, `un palo`, `una luca`). Before another number they are an article and are dropped (`un cuatro coma tres palos`).
- **Verbs** may come without accents (`gaste`, `pague`, `compre`, `recibi`, `me llego`). Case is ignored. The default kind is expense.
- **Dates**
  - `hoy/today`, `ayer/yesterday`, `antier/anteayer`, and a weekday with or without `el`/`on` and with or without accent.
  - A weekday is the most recent past one, and today's own weekday means a week ago (`el jueves` on a Thursday is -7). The spec says "the most recent past one"; this reads "past" as strictly before today.
  - The date word may be anywhere in its movement.
  - A date at the very start of the sentence covers every movement that has no date of its own (`antier gasté ... y ...`, both -2). A movement with its own date keeps it (`ayer ... y hoy ...`).
- **Category:** tried in the order of spec 5.2, and the name is compared ignoring accents and case on both sides: (1) the usual category of that name, (2) a category with that name, (3) none. There are no partial matches: `cafetería` does not match `Café`, `transportes` does not match `Transporte`.
- **Unread:** a movement with no readable amount is unread as a whole (`compré pan`, `ayer fui al cine`, `me de ópalo en el éxito`). Text with no amount that sits next to a movement is part of its name, never unread.

## Review Focus decisions

### "15 lukas" in EUR (and "palos" in USD)

**Decision: unread.** `"15 lukas"` with `currency: "EUR"` expects `drafts: []` and `unread: ["15 lukas"]`.

Reasoning:

- The spec says `lukas`, `luca` and `palos` count only in COP, so they cannot multiply here.
- Reading it as a plain 15 would be a guess: whoever says "15 lukas" means thousands, so 15 EUR is wrong by a factor of 1.000. A believable 15 EUR draft is also easy to save without noticing.
- Unread keeps the words in front of the person and nothing is dropped silently.
- A parser must recognize the slang unit in every currency (so it knows not to take "15" alone) and refuse to convert it outside COP.

The same applies to `una luca`, `2 palos` and the like in EUR and USD. In a mixed sentence only the slang movement is unread (`focus-eur-partial`: `15 mil` still becomes a draft). `focus-cop-lukas-still-count` shows the COP counterpart.

### "ayer" across a month boundary

`focus-ayer-month-boundary`: `today` 2026-10-01, `timeZone` `America/Bogota`, "ayer" is `2026-09-30`. The year, February and leap-day boundaries are covered too (`focus-ayer-year-boundary`, `focus-antier-month-boundary`, `focus-ayer-leap-day`, `date-weekday-month-boundary`).

## Where the cases come from

Ids start with their group:

| Prefix | What it covers |
|---|---|
| `spike-` | The 20 sentences of the voice spike (`docs/superpowers/reports/2026-10-22-stage-3-voice-spike.md`), with the expected drafts of that table: 25 movements. |
| `real-` | What Vosk and Whisper actually wrote for those sentences: no accents, number words, mishearings. They pin the tolerance for accentless verbs, `lucas`, and number words, and keep digits-only output working. |
| `amount-` | Every amount form of spec 5.2, in es and en, for COP, EUR and USD. |
| `focus-` | The Review Focus cases above. |
| `date-` | hoy, ayer, antier, weekdays and the default. |
| `kind-` | Income verbs, expense verbs and the default. |
| `split-` | Where a sentence is one movement and where it is several. |
| `category-` | Usual name, category name ignoring accents, and none. |
| `unread-` | Sentences with nothing to read. |

Notes on the `real-` cases:

- `real-vosk-*` are the Vosk free-pass transcripts, verbatim from the spike report (phone run). The report does not print the merged two-pass (v2) text, so there are no merged cases; the merged form of s08 is covered by `split-no-connector-leading-date`.
- Seven Vosk transcripts equal the spike sentence (s04, s09, s11, s12, s13, s15, s16), so the `spike-` case already covers them. The others are in: s01, s02, s03, s05, s06, s07, s08, s10, s14, s17, s18, s19, s20. s19 differs from the spike sentence (no comma).
- Misheard words stay in the name and a destroyed amount is `unread`, with no correction. For example s03 is `que riendo`, s05 is `me pagar` (not an income verb, so an expense), s08 is `gastos` and `taxi mercado` (the lost `doce` makes a bare `mil`, which is 1.000), s10 is `spend so learnt lunch and tree coffee`, and s07 is unread. The person fixes the name in the preview. The amount, kind and date are what these cases protect.
- The `real-whisper-*` cases are extra; Whisper is not the chosen engine.
