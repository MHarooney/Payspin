import { randomBytes } from 'crypto';

export function generateShortCode(length = 8): string {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const bytes = randomBytes(length);
  let result = '';
  for (let i = 0; i < length; i++) {
    result += alphabet[bytes[i] % alphabet.length];
  }
  return result;
}

export function ibanLast4(iban: string): string {
  const normalized = iban.replace(/\s+/g, '');
  return normalized.slice(-4);
}

export function extractIbanFromAccount(account: {
  accountIdentifications?: Array<{ type: string; identification: string }>;
}): string | null {
  const idents = account.accountIdentifications ?? [];
  const iban = idents.find((i) => i.type === 'IBAN');
  return iban?.identification ?? null;
}
