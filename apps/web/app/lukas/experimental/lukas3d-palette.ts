/**
 * The 3D Lukas' colors: art, not UI. They are picked from the character concept
 * (docs/brand/lukas-mascot-concept.webp) and only ever reach WebGL materials, never the DOM, so
 * they are literal values here instead of design tokens (which stay the source for every color on
 * the page). Keep them in this one module.
 */
export const LUKAS_3D_PALETTE = {
  /** The coin's body and raised rim: warm gold. */
  gold: "#ffad00",
  /** The ridged edge, a shade deeper so the ridges read. */
  goldEdge: "#c97000",
  /** The face disc inside the rim: a touch lighter and less metallic, like the concept's face. */
  goldFace: "#ffc01f",
  /** Arms, legs and hands. */
  limb: "#3b1f52",
  /** Sneakers. */
  sneaker: "#ff8fb3",
  /** Soles, laces, toe caps. */
  sole: "#fff4f7",
  /** Eye whites. */
  sclera: "#ffffff",
  /** Irises and the closed happy eyes. */
  iris: "#3c210f",
  pupil: "#0d0604",
  /** Eyebrows. */
  brow: "#4a2812",
  /** Rosy cheeks. */
  cheek: "#ff8b7c",
  /** Inside of the open mouth, the tongue and the teeth. */
  mouth: "#6b1626",
  tongue: "#ff6f8d",
  teeth: "#ffffff",
  /** Sparkles when celebrating (the concept's gold and mint). */
  sparkleGold: "#fff1a1",
  sparkleMint: "#8dffcf",
  /** Lights: a warm key, a soft lavender sky and a violet rim like the concept's glow. */
  keyLight: "#fff3dd",
  sky: "#f4ecff",
  ground: "#3a1f6e",
  rimLight: "#b48cff",
} as const;
