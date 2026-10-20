export function normalizeName(s: string): string {
  return s
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "");
}

const STYLES: [string[], { icon: string; color: string }][] = [
  [["supermercado", "mercado", "groceries"], { icon: "cart", color: "orange" }],
  [["restaurante", "restaurant", "comida", "food"], { icon: "cutlery", color: "red" }],
  [["ocio", "leisure", "entretenimiento"], { icon: "star", color: "purple" }],
  [["casa", "home", "hogar", "rent", "arriendo"], { icon: "house", color: "indigo" }],
  [["transporte", "transport"], { icon: "car", color: "blue" }],
  [["suscripciones", "subscriptions"], { icon: "umbrella", color: "pink" }],
  [["vida", "salud", "health"], { icon: "heart", color: "amber" }],
  [["taxes", "impuestos"], { icon: "document", color: "yellow" }],
  [["salario", "salary", "sueldo"], { icon: "salary", color: "green" }],
  [["investimento", "inversion", "investment"], { icon: "chart", color: "teal" }],
  [["viagem", "viaje", "travel"], { icon: "plane", color: "sky" }],
  [["things", "cosas"], { icon: "box", color: "gray" }],
];

const BY_NAME = new Map(STYLES.flatMap(([names, style]) => names.map((n) => [n, style] as const)));
const FALLBACK = { icon: "tag", color: "gray" };

/** Default icon and color for a category name, so imported categories look right out of the box. */
export function categoryStyle(name: string): { icon: string; color: string } {
  return { ...(BY_NAME.get(normalizeName(name)) ?? FALLBACK) };
}
