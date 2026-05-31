/** ISO 13616 IBAN lengths by country code. */
export const IBAN_LENGTHS: Record<string, number> = {
  AD: 24, AE: 23, AL: 28, AT: 20, AZ: 28, BA: 20, BE: 16, BG: 22, BH: 22,
  BR: 29, BY: 28, CH: 21, CR: 22, CY: 28, CZ: 24, DE: 22, DK: 18, DO: 28,
  EE: 20, EG: 29, ES: 24, FI: 18, FO: 18, FR: 27, GB: 22, GE: 22, GI: 23,
  GL: 18, GR: 27, GT: 28, HR: 21, HU: 28, IE: 22, IL: 23, IS: 26, IT: 27,
  JO: 30, KW: 30, KZ: 20, LB: 28, LC: 32, LI: 21, LT: 20, LU: 20, LV: 21,
  MC: 27, MD: 24, ME: 22, MK: 19, MR: 27, MT: 31, MU: 30, NL: 18, NO: 15,
  PK: 24, PL: 28, PS: 29, PT: 25, QA: 29, RO: 24, RS: 22, SA: 24, SE: 24,
  SI: 19, SK: 24, SM: 27, TN: 24, TR: 26, UA: 29, VG: 24, XK: 20,
};

export function normalizeIban(iban: string): string {
  return iban.replace(/\s+/g, '').toUpperCase();
}

export function validateIbanMod97(iban: string): boolean {
  const normalized = normalizeIban(iban);
  if (!/^[A-Z]{2}[0-9]{2}[A-Z0-9]+$/.test(normalized) || normalized.length < 15) {
    return false;
  }
  const rearranged = normalized.slice(4) + normalized.slice(0, 4);
  const numeric = rearranged.replace(/[A-Z]/g, (char) => String(char.charCodeAt(0) - 55));
  let remainder = 0;
  for (const digit of numeric) {
    remainder = (remainder * 10 + Number(digit)) % 97;
  }
  return remainder === 1;
}

/**
 * Extract the ISO 3166-1 alpha-2 country code from an IBAN.
 * Returns the 2-letter code when the prefix is a known IBAN country, else null.
 * Does not run the full mod-97 checksum so it can be used on stored IBANs that
 * were already validated at insert time.
 */
export function ibanCountry(iban: string): string | null {
  const normalized = normalizeIban(iban);
  const country = normalized.slice(0, 2);
  if (!/^[A-Z]{2}$/.test(country)) return null;
  if (IBAN_LENGTHS[country] === undefined) return null;
  return country;
}

export function validateIban(iban: string): string | null {
  const normalized = normalizeIban(iban);
  if (!normalized) return 'IBAN is required';

  const country = normalized.slice(0, 2);
  if (!/^[A-Z]{2}$/.test(country)) {
    return 'IBAN must start with a 2-letter country code';
  }

  const expectedLength = IBAN_LENGTHS[country];
  if (expectedLength === undefined) {
    return 'Unknown IBAN country code';
  }
  if (normalized.length !== expectedLength) {
    return `Invalid IBAN length for ${country}`;
  }
  if (!validateIbanMod97(normalized)) {
    return 'Invalid IBAN checksum';
  }
  return null;
}
