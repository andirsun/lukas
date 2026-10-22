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
- A parser **never throws**: any text, however long or odd (digit runs, emoji, punctuation), gives drafts and unread fragments.

## Conventions the cases pin

The spec leaves these open, and the expected values rely on them. If the parser needs to change one, change it here too.

- **Names**
  - Lowercase, in the spoken spelling (accents kept: `éxito`, `café`).
  - Dropped: the verb, the amount (with its currency word, like "euros" or "dollars"), the date word, and the function words `en de para por on for` plus the articles `el la los las un una the a an`.
  - Everything else stays, in order, so a misheard word stays in the name (`este almuerzo`, `rapid`).
  - What remains can be empty: `""`.
  - **Words keep their digits:** a word starts with a letter and runs through the letters and digits glued to it, so `D1` and `MiTienda24` are names (`d1`, `mitienda24`), never an amount. A number starts only with a digit (`15k`, `15mil` is `15` then `mil`).
  - **Except a scale word:** when the letters of a word are a scale word (`mil`, `millón`/`millon`, `millones`, `palo(s)`, `luca(s)`/`luka(s)`, `thousand`, `million(s)`, `k`), the digits glued after it are a number of their own. So `2mil500` is `2 mil 500`, which is 2.500 (`gasté 2mil500 en el bus` is 250000 cents, named `bus`). `15mil500` is 15.500, and `1millon200` is `1 millón 200`, which is 1.000.200 by the scale rules (a number after a scale adds to it). `D1` and `MiTienda24` are not affected: `d` and `mitienda` are not scale words.
  - **"A name"** (in the rules below) is any word that is not an amount word, a date word, a function word or the verb. A misheard verb is therefore a name: `gastos` in `gastos de mil` is one, and so is `spend` (the verb is `spent`).
- **Where a name sits:** before the amount (`uber siete mil`), after it (`gasté 8 mil en taxi`) or around it (`pagué el arriendo, un millón`).
- **Splitting**
  - A connector (`y`, `and`, `,`, `también`, `also`) starts a new movement only when the movement so far has an amount and the text after the connector has an amount. So `pan y leche 8 mil`, `gasté 8 mil en pan y leche` and `spent 12 on bread and milk` are one movement.
  - "The text after the connector" ends at the next connector. So `gasté 8 mil en pan y leche, 3 mil en huevos` splits at the comma, not at the `y` (`split-connector-scope`).
  - A decimal comma (`9,50`) or a thousands comma (`1,200`) is not a connector.
  - `y` inside a number word (`treinta y cinco mil`) is not a connector. In `siete mil quinientos y cinco mil`, `quinientos y cinco` is not a number, so the `y` splits.
  - **No connector:** an amount that follows a movement already holding an amount and a name starts a new movement, even with no connector. The words between the two amounts (the middle) go to the earlier movement if it has no name before its amount (`gasté doce mil en taxi cuarenta mil en mercado`: `en taxi` is the first movement's). They go to the later movement if the earlier one already has a name before its amount (`taxi doce mil mercado cuarenta mil`: `mercado` is the second movement's). A verb or a date word in the middle starts the later movement, with what follows it (`ayer gasté 5 mil en taxi hoy 3 mil en café`). Words after the last amount stay with the last movement.
  - **Same amount:** number words with no name between them are one amount when they form a valid number (`mil quinientos` is 1.500, `veintidós mil novecientos` is 22.900). They are not two movements.
  - **No name at all:** two amounts with no name anywhere in the movement and that do not form one valid number (`gasté 12 mil 40 mil`) are not split, because the first movement holds no name, and not merged. The whole movement is unread (`unread: ["gasté 12 mil 40 mil"]`).
- **Number forms:**
  - **Digits read the same in every locale and currency.**
    - A dot or comma followed by **exactly three digits** is a thousands separator, because cents have two digits: `15.000`, `1.500.000`, `15,000`, `$25,000` and `2,500` in COP are 15.000, 25.000 and 2.500, and `1,500 €` and `9,999` in EUR are 1.500 € and 9.999 €.
    - A last dot or comma followed by **one or two digits** is the decimal: `9,50` (950 cents), `12.50`, `4,3 palos`, `1.234,56`, `1,200.50`.
    - In es, a space before exactly three digits is thousands too (`120 000`; Whisper writes that).
    - A dot or comma before **four or more digits** (`12,5000`) is neither, so the movement is unread (`amount-separator-four-digits-unread`).
  - **Thousands before a scale word is ambiguous, so unread:** `4,300 palos` could be 4,3 palos or 4.300 palos, and `1,500k` is the same.
  - `k` after digits is x1.000, in any currency, glued or not (`15k`, `15 k`). `mil`, `millón` and `millones` work with digits and with words.
  - **COP is whole pesos.** In COP, an amount with a fractional peso and no scale word is unread: `9,50`, `9.50`, `nueve con cincuenta` and en `9.50` (`amount-cop-fraction-*`, `amount-en-cop-fraction-unread`). A decimal before a scale word is fine, because it comes out whole (`4,3 palos`, `2,5 millones`, `1.5k`). EUR and USD keep their cents (`9,50` and `9.50` are 950).
  - Bare `mil` is 1.000 (`gasté mil en chicle`, and the `mil` left by a misheard `doce` in `gastos de mil`).
  - **Scale words** are `mil`, `millón`/`millones`, `thousand`, `million`, `k`, and the COP slang units `palo(s)` and `luca(s)`/`lukas`.
  - `con` joins units and cents (`nueve con cincuenta`, `9 euros con 50`). In en, `and … cents` does (`twelve dollars and fifty cents`).
  - `coma` (es) and `point` (en) are the decimal in words. The decimals keep their written length: `10 coma 05` is 10,05 and `cuatro coma tres` is 4,3.
  - A larger scale right after a scale multiplies everything before it: `mil millones` is 1.000.000.000 (then over the cap, so unread).
  - `y medio`/`y media` after a scale adds half of it: `un palo y medio` is 1.500.000, `mil y medio` is 1.500. `medio` before a scale is half of it (`medio palo`).
  - en: a number from 1 to 99 before `hundred` multiplies it (`two hundred fifty`, `twelve hundred` is 1.200). Two number words where the second is 10 to 99, with no scale, are units and cents (`twelve fifty` is 12,50).
  - **The cap:** an amount above 999.999.999 (in currency units), or of 0, is unread, whatever the digits or words. It is never cut, rounded or wrapped.
  - Number words may come without accents (`veintidos`, `dieciseis`).
  - `un` and `una` are numbers only before a scale word (see above: `un millón`, `un palo`, `una luca`). Before another number they are an article and are dropped (`un cuatro coma tres palos`).
- **Verbs** may come without accents (`gaste`, `pague`, `compre`, `recibi`, `me llego`). Case is ignored.
- **The context carries over.** The sentence is read left to right:
  - **Kind:** a verb sets the kind of its movement and of every later one, until another verb sets another. Before any verb, the kind is expense. `recibí 2 millones de prima y 200 mil de bono` is two incomes, and `me pagaron 2 millones y gasté 50 mil en mercado` is an income, then an expense.
  - **Date:** a date word sets the date of its movement and of every later one, until another date word. Before any date word, the date is today. `gasté ayer 5 mil en pan y 3 mil en café` dates both yesterday, and `gasté 5 mil en pan y ayer 3 mil en café` dates only the second.
  - Verbs and date words in an unread movement carry over too.
- **Dates**
  - `hoy/today`, `ayer/yesterday`, `antier/anteayer`, and a weekday with or without `el`/`on` and with or without accent.
  - A weekday is the most recent past one, and today's own weekday means a week ago (`el jueves` on a Thursday is -7). The spec says "the most recent past one"; this reads "past" as strictly before today.
  - The date word may be anywhere in its movement, and it carries over (above): `antier gasté ... y ...` dates both -2, and `ayer ... y hoy ...` keeps each its own.
- **Category:** tried in the order of spec 5.2, and the name is compared ignoring accents and case on both sides: (1) the usual category of that name, (2) a category with that name, (3) none. There are no partial matches: `cafetería` does not match `Café`, `transportes` does not match `Transporte`.
  - **Only categories of the draft's kind count**, in both steps. A transaction takes its sign from its category, so an income draft must never get an expense category. A usual pair counts only when its category is among `categories` and of the draft's kind; otherwise matching goes on to step 2. With no match of the same kind, `categoryId` is null (`category-kind-filter-usual`, `category-kind-filter-name`, `category-kind-filter-falls-through`).
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
