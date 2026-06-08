import { ibanCountry, normalizeIban } from '@payspin/validators';

export interface PayeeAccountIdentification {
  type: string;
  identification: string;
}

export interface ResolvedPayeeAccount {
  /** Account identifications to send as the Yapily `payee`. */
  identifications: PayeeAccountIdentification[];
  /** Currency the payment must be denominated in for this scheme. */
  currency: string;
}

/**
 * UK IBANs follow ISO 13616 + the UK national format:
 *   GB kk BBBB SSSSSS AAAAAAAA
 *   └┬┘ └┬┘ └─┬─┘ └──┬─┘ └───┬──┘
 *  country check bank  sort   account
 * i.e. a 4-char bank identifier, a 6-digit sort code, and an 8-digit account
 * number. These are the canonical positions and let us derive Faster Payments
 * details from any GB IBAN without storing anything bank-specific.
 */
function deriveUkSortCodeAccount(
  normalizedIban: string,
): { sortCode: string; accountNumber: string } | null {
  const sortCode = normalizedIban.slice(8, 14);
  const accountNumber = normalizedIban.slice(14, 22);
  if (!/^\d{6}$/.test(sortCode) || !/^\d{8}$/.test(accountNumber)) {
    return null;
  }
  return { sortCode, accountNumber };
}

/**
 * Build the Yapily `payee` account identifications (and required currency) for
 * a payment to the given IBAN, following each scheme's domestic-payment rules:
 *
 * - **UK (GB):** Faster Payments requires `SORT_CODE` + `ACCOUNT_NUMBER` and is
 *   settled in GBP. UK banks reject a raw IBAN as the payee identifier, so we
 *   derive the sort code + account number from the IBAN structure.
 * - **SEPA (everything else):** the IBAN is the payee identifier, settled in
 *   the payment's own currency (EUR for SEPA).
 *
 * This is purely scheme-driven — no institution- or test-specific values — so
 * it behaves identically for sandbox and real banks.
 */
export function resolvePayeeAccount(
  iban: string,
  fallbackCurrency: string,
): ResolvedPayeeAccount {
  const normalized = normalizeIban(iban);
  const country = ibanCountry(normalized);

  if (country === 'GB') {
    const uk = deriveUkSortCodeAccount(normalized);
    if (uk) {
      return {
        identifications: [
          { type: 'SORT_CODE', identification: uk.sortCode },
          { type: 'ACCOUNT_NUMBER', identification: uk.accountNumber },
        ],
        currency: 'GBP',
      };
    }
  }

  return {
    identifications: [{ type: 'IBAN', identification: normalized }],
    currency: fallbackCurrency,
  };
}
