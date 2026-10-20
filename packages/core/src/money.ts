export class InvalidAmountError extends Error {
  constructor(readonly input: string) {
    super(`Invalid amount: ${JSON.stringify(input)}`);
    this.name = "InvalidAmountError";
  }
}

const DECIMAL = /^(-?)(\d+)(?:\.(\d{1,2}))?$/;

/** Parses a dot-decimal string ("-30.70") into integer minor units (-3070) without floats. */
export function parseDecimalToMinor(input: string): number {
  const match = DECIMAL.exec(input.trim());
  if (!match) throw new InvalidAmountError(input);
  const [, sign, whole = "0", fraction = ""] = match;
  const minor = Number(whole) * 100 + Number(fraction.padEnd(2, "0"));
  if (!Number.isSafeInteger(minor)) throw new InvalidAmountError(input);
  return sign === "-" ? -minor : minor;
}
