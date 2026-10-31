/**
 * What money is called around the Spanish-speaking world, for the Spanish headline's marker
 * ("Tus lukas, por fin claras." → "Tu lana, por fin clara." → …). Each word carries its gender
 * and number, so "Tu(s)" and "clar(a/o)(s)" agree with it. The first is the prerendered one: it
 * must match the `landing.hero.headline` message.
 */
export interface MoneyWord {
  word: string;
  /** The flag of where it is said, shown after the marker. */
  flag: string;
  plural: boolean;
  feminine: boolean;
}

export const MONEY_WORDS: readonly [MoneyWord, ...MoneyWord[]] = [
  { word: "lukas", flag: "🇨🇴", plural: true, feminine: true }, // Colombia
  { word: "lana", flag: "🇲🇽", plural: false, feminine: true }, // México
  { word: "guita", flag: "🇦🇷", plural: false, feminine: true }, // Argentina
  { word: "pasta", flag: "🇪🇸", plural: false, feminine: true }, // España
  { word: "plata", flag: "🇨🇱", plural: false, feminine: true }, // Chile
  { word: "chavos", flag: "🇵🇷", plural: true, feminine: false }, // Puerto Rico
  { word: "pisto", flag: "🇬🇹", plural: false, feminine: false }, // Guatemala
  { word: "cuartos", flag: "🇩🇴", plural: true, feminine: false }, // República Dominicana
  { word: "reales", flag: "🇻🇪", plural: true, feminine: false }, // Venezuela
];

/** How long each word stays before the next one rolls in, in ms. */
export const MONEY_WORD_HOLD = 2800;

/** The endings that agree with a word: "Tu" + `det`, "clar" + `adj`. */
export function agreement({ plural, feminine }: MoneyWord): { det: string; adj: string } {
  return { det: plural ? "s" : "", adj: (feminine ? "a" : "o") + (plural ? "s" : "") };
}

/** The whole headline for a word, as it reads. */
export function headlineFor(entry: MoneyWord): string {
  const { det, adj } = agreement(entry);
  return `Tu${det} ${entry.word}, por fin clar${adj}.`;
}
