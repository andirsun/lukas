import type { Profile } from "./lukitas.ts";

type Locale = Profile["locale"];

/**
 * A prompt the person can pick in their assistant (spec §4.5). Its texts come in the person's
 * locale; `args` describes its optional arguments (all strings, as prompts take them).
 */
export interface AssistantPrompt {
  name: "revision-del-mes" | "anotar-gastos" | "como-voy";
  title(locale: Locale): string;
  description(locale: Locale): string;
  args: readonly { name: string; required: false; description(locale: Locale): string }[];
  messages(
    locale: Locale,
    args: Record<string, string | undefined>,
  ): { role: "user"; text: string }[];
}

type Texts = Record<Locale, string>;
const pick = (texts: Texts) => (locale: Locale) => texts[locale] ?? texts.es;

const monthReview: AssistantPrompt = {
  name: "revision-del-mes",
  title: pick({
    es: "Revisión del mes",
    en: "Month review",
    it: "Revisione del mese",
    pt: "Revisão do mês",
  }),
  description: pick({
    es: "El resumen del mes, las categorías que más crecieron frente al mes anterior y los presupuestos en riesgo.",
    en: "The month's overview, the categories that grew most against last month, and the budgets at risk.",
    it: "Il riepilogo del mese, le categorie cresciute di più rispetto al mese scorso e i budget a rischio.",
    pt: "O resumo do mês, as categorias que mais cresceram face ao mês anterior e os orçamentos em risco.",
  }),
  args: [
    {
      name: "month",
      required: false,
      description: pick({
        es: "El mes como AAAA-MM; vacío para el mes actual",
        en: "The month as YYYY-MM; empty for the current month",
        it: "Il mese come AAAA-MM; vuoto per il mese corrente",
        pt: "O mês como AAAA-MM; vazio para o mês atual",
      }),
    },
  ],
  messages(locale, args) {
    const month = args.month?.trim();
    const texts: Texts = {
      es: `Haz la revisión de ${month ? `mi mes ${month}` : "este mes"} en Lukitas. Usa get_month_overview para el resumen: ingresos, gastos y lo que queda. Luego compara con el mes anterior usando spending_by_category para cada uno de los dos meses y dime qué categorías crecieron más. Termina con los presupuestos en riesgo (cerca del límite o pasados). Sé breve y concreto, con los montos tal como vienen.`,
      en: `Review ${month ? `my month ${month}` : "this month"} in Lukitas. Use get_month_overview for the overview: income, expenses and what is left. Then compare with the previous month using spending_by_category for each of the two months and tell me which categories grew most. End with the budgets at risk (near the limit or over). Keep it short and concrete, with the amounts as they come.`,
      it: `Fai la revisione di ${month ? `il mio mese ${month}` : "questo mese"} in Lukitas. Usa get_month_overview per il riepilogo: entrate, spese e quanto resta. Poi confronta con il mese precedente usando spending_by_category per ciascuno dei due mesi e dimmi quali categorie sono cresciute di più. Chiudi con i budget a rischio (vicini al limite o superati). Sii breve e concreto, con gli importi come arrivano.`,
      pt: `Faz a revisão de ${month ? `o meu mês ${month}` : "este mês"} no Lukitas. Usa get_month_overview para o resumo: receitas, despesas e o que falta. Depois compara com o mês anterior usando spending_by_category para cada um dos dois meses e diz-me que categorias mais cresceram. Termina com os orçamentos em risco (perto do limite ou ultrapassados). Sê breve e concreto, com os montantes tal como vêm.`,
    };
    return [{ role: "user", text: pick(texts)(locale) }];
  },
};

const dictateExpenses: AssistantPrompt = {
  name: "anotar-gastos",
  title: pick({
    es: "Anotar gastos",
    en: "Log expenses",
    it: "Annotare spese",
    pt: "Registar despesas",
  }),
  description: pick({
    es: "Dicta varios gastos; el asistente los confirma contigo antes de guardarlos.",
    en: "Dictate several expenses; the assistant confirms them with you before saving.",
    it: "Detta più spese; l'assistente le conferma con te prima di salvarle.",
    pt: "Dita várias despesas; o assistente confirma-as contigo antes de as guardar.",
  }),
  args: [
    {
      name: "gastos",
      required: false,
      description: pick({
        es: "Los gastos, como los dirías: «18 lukas almuerzo, 12 de taxi»",
        en: "The expenses, as you would say them: “18k lunch, 12k taxi”",
        it: "Le spese, come le diresti: «pranzo 18 €, taxi 12 €»",
        pt: "As despesas, como as dirias: «almoço 18 €, táxi 12 €»",
      }),
    },
  ],
  messages(locale, args) {
    const list = args.gastos?.trim();
    const texts: Texts = {
      es: `Voy a dictarte varios gastos para Lukitas. Primero mira list_categories. Arma la lista con nombre, monto, categoría y fecha de cada uno (sin fecha es hoy), muéstramela y espera a que la confirme. Cuando diga que sí, guárdalos todos en una sola llamada a add_transactions.${list ? `\n\nMis gastos: ${list}` : " ¿Cuáles son?"}`,
      en: `I am going to dictate several expenses for Lukitas. First look at list_categories. Put together the list with the name, amount, category and date of each one (no date means today), show it to me and wait for me to confirm. When I say yes, save them all in a single add_transactions call.${list ? `\n\nMy expenses: ${list}` : " What are they?"}`,
      it: `Ti detterò alcune spese per Lukitas. Prima guarda list_categories. Prepara l'elenco con nome, importo, categoria e data di ciascuna (senza data è oggi), mostramelo e aspetta che lo confermi. Quando dico di sì, salvale tutte con una sola chiamata a add_transactions.${list ? `\n\nLe mie spese: ${list}` : " Quali sono?"}`,
      pt: `Vou ditar-te várias despesas para o Lukitas. Primeiro vê list_categories. Prepara a lista com nome, montante, categoria e data de cada uma (sem data é hoje), mostra-ma e espera que eu confirme. Quando eu disser que sim, guarda-as todas numa só chamada a add_transactions.${list ? `\n\nAs minhas despesas: ${list}` : " Quais são?"}`,
    };
    return [{ role: "user", text: pick(texts)(locale) }];
  },
};

const howAmIDoing: AssistantPrompt = {
  name: "como-voy",
  title: pick({
    es: "¿Cómo voy?",
    en: "How am I doing?",
    it: "Come sto andando?",
    pt: "Como estou?",
  }),
  description: pick({
    es: "Una respuesta corta: cuánto te queda este mes y cómo van los presupuestos.",
    en: "A short answer: what is left this month and how the budgets are going.",
    it: "Una risposta breve: quanto ti resta questo mese e come vanno i budget.",
    pt: "Uma resposta curta: quanto te falta este mês e como vão os orçamentos.",
  }),
  args: [],
  messages(locale) {
    const texts: Texts = {
      es: "¿Cómo voy este mes en Lukitas? Usa get_month_overview y respóndeme en dos o tres frases: cuánto me queda y qué presupuestos están cerca del límite o pasados.",
      en: "How am I doing this month in Lukitas? Use get_month_overview and answer in two or three sentences: what is left and which budgets are near the limit or over.",
      it: "Come sto andando questo mese in Lukitas? Usa get_month_overview e rispondimi in due o tre frasi: quanto mi resta e quali budget sono vicini al limite o superati.",
      pt: "Como estou este mês no Lukitas? Usa get_month_overview e responde-me em duas ou três frases: quanto me falta e que orçamentos estão perto do limite ou ultrapassados.",
    };
    return [{ role: "user", text: pick(texts)(locale) }];
  },
};

/** The three prompts, in a fixed order. */
export const PROMPTS: readonly AssistantPrompt[] = [monthReview, dictateExpenses, howAmIDoing];
