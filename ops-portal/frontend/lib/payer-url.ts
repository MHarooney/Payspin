const PAYER_BASE = process.env.NEXT_PUBLIC_PAYER_WEB_URL ?? 'http://localhost:3000';

export function payerUrl(shortCode: string): string {
  const base = PAYER_BASE.replace(/\/$/, '');
  return `${base}/${shortCode}`;
}

export function payerBaseUrl(): string {
  return PAYER_BASE.replace(/\/$/, '');
}
