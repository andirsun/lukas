import { describe, expect, it } from "vitest";
import es from "../../i18n/messages/es.json" with { type: "json" };
import { headlineFor, MONEY_WORDS } from "./money-words.ts";

describe("MONEY_WORDS", () => {
  it("starts with the prerendered headline", () => {
    const message = es.landing.hero.headline.replace(/<\/?mark>/g, "");
    expect(headlineFor(MONEY_WORDS[0])).toBe(message);
  });

  it("agrees in gender and number with every word", () => {
    expect(MONEY_WORDS.map(headlineFor)).toEqual([
      "Tus lukas, por fin claras.",
      "Tu lana, por fin clara.",
      "Tu guita, por fin clara.",
      "Tu pasta, por fin clara.",
      "Tu plata, por fin clara.",
      "Tus chavos, por fin claros.",
      "Tu pisto, por fin claro.",
      "Tus cuartos, por fin claros.",
      "Tus reales, por fin claros.",
    ]);
  });

  it("names each word once", () => {
    const words = MONEY_WORDS.map((w) => w.word);
    expect(new Set(words).size).toBe(words.length);
  });
});
