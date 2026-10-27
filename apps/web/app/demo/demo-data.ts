import type { CategoryKind } from "@lukas/core";
import type { Locale } from "../i18n/format.ts";

/**
 * The demo's invented person, "Valentina (demo)", and her money: what `createDemoBackend` builds
 * its in-memory account from. Nothing here is dated: the backend lays the transactions over the
 * last 3 months counted back from its clock, so the demo always looks current. No randomness: the
 * same seed and the same clock always give the same account.
 *
 * Amounts are in major units here (pesos, euros) and stored in hundredths like the API's, COP
 * included: 8.000 pesos is 800.000.
 */
export interface DemoSeed {
  profile: {
    /** Shown nowhere the API reaches (the profile has no name); it says who the demo is. */
    name: string;
    email: string;
    locale: Locale;
    timezone: string;
    currency: "COP" | "EUR";
  };
  categories: DemoCategory[];
  recurrences: DemoRecurrence[];
  /**
   * The current month's spending. Earlier months repeat it, scaled per category by
   * `pastMonths[n]` (one entry per month back), so the trend has some life in it.
   */
  month: DemoSpend[];
  pastMonths: Record<string, number>[];
}

export interface DemoCategory {
  /** Stable key within the seed; the backend gives each category a real id. */
  key: string;
  name: string;
  kind: CategoryKind;
  icon: string;
  color: string;
  /** Monthly budget (major units), from the first seeded month on; null for none. */
  budget: number | null;
}

export interface DemoRecurrence {
  key: string;
  name: string;
  category: string;
  /** Major units, negative for spending. */
  amount: number;
  dayOfMonth: number;
}

export interface DemoSpend {
  /** Day of the month, at most 20, so it exists in every month and is behind most "todays". */
  day: number;
  name: string;
  category: string;
  /** Major units, positive: they are all spending. */
  amount: number;
}

/** What every locale shares: the category keys, glyphs and tints (the onboarding's palette). */
const LOOKS: Record<string, { icon: string; color: string; kind: CategoryKind }> = {
  groceries: { icon: "🛒", color: "#ff9f1c", kind: "expense" },
  eating_out: { icon: "🍽️", color: "#ff5c7a", kind: "expense" },
  transport: { icon: "🚌", color: "#3fa7ff", kind: "expense" },
  home: { icon: "🏠", color: "#6d6bff", kind: "expense" },
  bills: { icon: "💡", color: "#ffe66d", kind: "expense" },
  health: { icon: "❤️", color: "#ff8fd8", kind: "expense" },
  fun: { icon: "⭐", color: "#a66bff", kind: "expense" },
  coffee: { icon: "☕", color: "#ffb547", kind: "expense" },
  salary: { icon: "💰", color: "#2fd388", kind: "income" },
};

function categories(
  names: Record<string, string>,
  budgets: Record<string, number | null>,
): DemoCategory[] {
  return Object.entries(LOOKS).map(([key, look]) => ({
    key,
    name: names[key] as string,
    ...look,
    budget: budgets[key] ?? null,
  }));
}

/**
 * Per category, how much the month before (and the one before that) spent compared with this one:
 * a calmer month for eating out, a dentist two months ago, and so on.
 */
const PAST_MONTHS: Record<string, number>[] = [
  {
    groceries: 1.08,
    eating_out: 0.7,
    transport: 1.2,
    bills: 1.05,
    health: 2.4,
    fun: 1.5,
    coffee: 0.9,
  },
  {
    groceries: 0.95,
    eating_out: 0.85,
    transport: 0.9,
    bills: 0.97,
    health: 0.5,
    fun: 0.8,
    coffee: 1.1,
  },
];

/**
 * Spanish: a Colombian in Bogotá, in pesos, so the lukas hint shows ("1.800.000 (1,8 palos)").
 * This month eating out goes over its budget, coffee comes near it, rent uses all of its own.
 */
const ES: DemoSeed = {
  profile: {
    name: "Valentina (demo)",
    email: "valentina@demo.lukas.app",
    locale: "es",
    timezone: "America/Bogota",
    currency: "COP",
  },
  categories: categories(
    {
      groceries: "Mercado",
      eating_out: "Restaurantes",
      transport: "Transporte",
      home: "Arriendo",
      bills: "Servicios",
      health: "Salud",
      fun: "Ocio",
      coffee: "Café",
      salary: "Salario",
    },
    {
      groceries: 900_000,
      eating_out: 300_000,
      transport: 250_000,
      home: 1_800_000,
      bills: 280_000,
      health: 150_000,
      fun: 200_000,
      coffee: 100_000,
    },
  ),
  recurrences: [
    { key: "rent", name: "Arriendo", category: "home", amount: -1_800_000, dayOfMonth: 1 },
    { key: "spotify", name: "Spotify", category: "fun", amount: -16_900, dayOfMonth: 12 },
    { key: "salary", name: "Salario", category: "salary", amount: 5_200_000, dayOfMonth: 28 },
  ],
  month: [
    { day: 1, name: "Recarga TuLlave", category: "transport", amount: 50_000 },
    { day: 2, name: "Mercado de la semana", category: "groceries", amount: 185_000 },
    { day: 2, name: "Tinto y pandebono", category: "coffee", amount: 8_000 },
    { day: 3, name: "Almuerzo con el equipo", category: "eating_out", amount: 48_000 },
    { day: 4, name: "Droguería", category: "health", amount: 45_000 },
    { day: 5, name: "Energía", category: "bills", amount: 98_000 },
    { day: 5, name: "Café", category: "coffee", amount: 8_000 },
    { day: 6, name: "Pizza con amigos", category: "eating_out", amount: 96_000 },
    { day: 7, name: "Internet", category: "bills", amount: 85_000 },
    { day: 7, name: "Café y croissant", category: "coffee", amount: 12_000 },
    { day: 8, name: "Taxi", category: "transport", amount: 18_000 },
    { day: 9, name: "Plaza de mercado", category: "groceries", amount: 64_000 },
    { day: 9, name: "Café", category: "coffee", amount: 8_000 },
    { day: 10, name: "Hamburguesas", category: "eating_out", amount: 62_000 },
    { day: 11, name: "Agua", category: "bills", amount: 31_000 },
    { day: 12, name: "Café", category: "coffee", amount: 8_000 },
    { day: 13, name: "Gasolina", category: "transport", amount: 80_000 },
    { day: 14, name: "Mercado de la semana", category: "groceries", amount: 212_000 },
    { day: 14, name: "Tinto y pandebono", category: "coffee", amount: 9_000 },
    { day: 15, name: "Cena de cumpleaños", category: "eating_out", amount: 136_000 },
    { day: 16, name: "Café", category: "coffee", amount: 8_000 },
    { day: 17, name: "Cine", category: "fun", amount: 32_000 },
    { day: 18, name: "Libro", category: "fun", amount: 48_000 },
    { day: 19, name: "Panadería", category: "groceries", amount: 18_000 },
    { day: 19, name: "Café", category: "coffee", amount: 8_000 },
    { day: 20, name: "Mercado del mes", category: "groceries", amount: 131_000 },
    { day: 20, name: "Café", category: "coffee", amount: 7_000 },
    { day: 20, name: "Café con Andrés", category: "coffee", amount: 10_000 },
  ],
  pastMonths: PAST_MONTHS,
};

/** English: someone in Lisbon, in euros. Same story as the Spanish one. */
const EN: DemoSeed = {
  profile: {
    name: "Valentina (demo)",
    email: "valentina@demo.lukas.app",
    locale: "en",
    timezone: "Europe/Lisbon",
    currency: "EUR",
  },
  categories: categories(
    {
      groceries: "Groceries",
      eating_out: "Eating out",
      transport: "Transport",
      home: "Rent",
      bills: "Bills",
      health: "Health",
      fun: "Fun",
      coffee: "Coffee",
      salary: "Salary",
    },
    {
      groceries: 400,
      eating_out: 180,
      transport: 90,
      home: 950,
      bills: 140,
      health: 60,
      fun: 80,
      coffee: 40,
    },
  ),
  recurrences: [
    { key: "rent", name: "Rent", category: "home", amount: -950, dayOfMonth: 1 },
    { key: "spotify", name: "Spotify", category: "fun", amount: -6.99, dayOfMonth: 12 },
    { key: "salary", name: "Salary", category: "salary", amount: 2_300, dayOfMonth: 28 },
  ],
  month: [
    { day: 1, name: "Metro pass", category: "transport", amount: 40 },
    { day: 2, name: "Weekly shop", category: "groceries", amount: 92.4 },
    { day: 2, name: "Coffee", category: "coffee", amount: 2.6 },
    { day: 3, name: "Team lunch", category: "eating_out", amount: 18.5 },
    { day: 4, name: "Pharmacy", category: "health", amount: 14.5 },
    { day: 5, name: "Electricity", category: "bills", amount: 54.2 },
    { day: 5, name: "Coffee", category: "coffee", amount: 2.6 },
    { day: 6, name: "Pizza with friends", category: "eating_out", amount: 42 },
    { day: 7, name: "Internet", category: "bills", amount: 35 },
    { day: 7, name: "Coffee and a croissant", category: "coffee", amount: 4.2 },
    { day: 8, name: "Taxi", category: "transport", amount: 12.4 },
    { day: 9, name: "Market", category: "groceries", amount: 21.3 },
    { day: 9, name: "Coffee", category: "coffee", amount: 2.6 },
    { day: 10, name: "Burgers", category: "eating_out", amount: 24.9 },
    { day: 11, name: "Water", category: "bills", amount: 18.4 },
    { day: 12, name: "Coffee", category: "coffee", amount: 2.6 },
    { day: 13, name: "Train tickets", category: "transport", amount: 18.9 },
    { day: 14, name: "Weekly shop", category: "groceries", amount: 104.75 },
    { day: 14, name: "Coffee and a pastel de nata", category: "coffee", amount: 3.1 },
    { day: 15, name: "Birthday dinner", category: "eating_out", amount: 112.6 },
    { day: 16, name: "Coffee", category: "coffee", amount: 2.6 },
    { day: 17, name: "Cinema", category: "fun", amount: 9.5 },
    { day: 18, name: "Book", category: "fun", amount: 18.9 },
    { day: 19, name: "Bakery", category: "groceries", amount: 6.8 },
    { day: 19, name: "Coffee", category: "coffee", amount: 2.6 },
    { day: 20, name: "Big shop", category: "groceries", amount: 58.2 },
    { day: 20, name: "Coffee", category: "coffee", amount: 2.4 },
    { day: 20, name: "Coffee with Andrés", category: "coffee", amount: 8.5 },
  ],
  pastMonths: PAST_MONTHS,
};

/**
 * The euro months of the English seed, without the words: the day, the category and the amount of
 * each purchase, in order. Italian and Portuguese tell the same story (eating out over its budget,
 * coffee near it, rent using all of its own) with their own names, in `euroSeed`.
 */
const EURO_MONTH: Omit<DemoSpend, "name">[] = EN.month.map(({ day, category, amount }) => ({
  day,
  category,
  amount,
}));

/** The names of `EURO_MONTH`'s purchases, in the same order. */
interface EuroWords {
  locale: Locale;
  timezone: string;
  categories: Record<string, string>;
  recurrences: { rent: string; salary: string };
  month: string[];
}

/** The English seed's euros and story, told in another language: the same amounts and budgets. */
function euroSeed(words: EuroWords): DemoSeed {
  const budgets = Object.fromEntries(
    EN.categories.map((c) => [c.key, c.budget] as const),
  ) as Record<string, number | null>;
  return {
    profile: { ...EN.profile, locale: words.locale, timezone: words.timezone },
    categories: categories(words.categories, budgets),
    recurrences: EN.recurrences.map((r) => ({
      ...r,
      name:
        r.key === "rent"
          ? words.recurrences.rent
          : r.key === "salary"
            ? words.recurrences.salary
            : r.name,
    })),
    month: EURO_MONTH.map((spend, i) => ({ ...spend, name: words.month[i] as string })),
    pastMonths: PAST_MONTHS,
  };
}

/** Italian: someone in Milan, in euros. */
const IT: DemoSeed = euroSeed({
  locale: "it",
  timezone: "Europe/Rome",
  categories: {
    groceries: "Spesa",
    eating_out: "Ristoranti",
    transport: "Trasporti",
    home: "Affitto",
    bills: "Bollette",
    health: "Salute",
    fun: "Svago",
    coffee: "Caffè",
    salary: "Stipendio",
  },
  recurrences: { rent: "Affitto", salary: "Stipendio" },
  month: [
    "Abbonamento ai mezzi",
    "Spesa settimanale",
    "Caffè",
    "Pranzo con il team",
    "Farmacia",
    "Luce",
    "Caffè",
    "Pizza con gli amici",
    "Internet",
    "Caffè e cornetto",
    "Taxi",
    "Mercato",
    "Caffè",
    "Hamburger",
    "Acqua",
    "Caffè",
    "Biglietti del treno",
    "Spesa settimanale",
    "Caffè e pasticcino",
    "Cena di compleanno",
    "Caffè",
    "Cinema",
    "Libro",
    "Panificio",
    "Caffè",
    "Spesa grande",
    "Caffè",
    "Caffè con Andrés",
  ],
});

/** European Portuguese: someone in Lisbon, in euros. */
const PT: DemoSeed = euroSeed({
  locale: "pt",
  timezone: "Europe/Lisbon",
  categories: {
    groceries: "Supermercado",
    eating_out: "Restaurantes",
    transport: "Transportes",
    home: "Renda",
    bills: "Contas",
    health: "Saúde",
    fun: "Lazer",
    coffee: "Café",
    salary: "Salário",
  },
  recurrences: { rent: "Renda", salary: "Salário" },
  month: [
    "Passe de metro",
    "Compras da semana",
    "Café",
    "Almoço com a equipa",
    "Farmácia",
    "Eletricidade",
    "Café",
    "Pizza com amigos",
    "Internet",
    "Café e croissant",
    "Táxi",
    "Mercado",
    "Café",
    "Hambúrgueres",
    "Água",
    "Café",
    "Bilhetes de comboio",
    "Compras da semana",
    "Café e pastel de nata",
    "Jantar de anos",
    "Café",
    "Cinema",
    "Livro",
    "Padaria",
    "Café",
    "Compras grandes",
    "Café",
    "Café com o Andrés",
  ],
});

/** The demo's seed per language: the page's language picks the person (and her currency). */
export const DEMO_SEED: Record<Locale, DemoSeed> = { es: ES, en: EN, it: IT, pt: PT };
