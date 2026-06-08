import { PaymentRequestPayload } from '@payspin/pisp-provider';
import { PayeeAccountIdentification } from '../../domain/utils/payee-account';

export interface BuildPaymentRequestInput {
  amountCents: number;
  currency: string;
  payeeIdentifications: PayeeAccountIdentification[];
  beneficiaryName: string;
  reference: string;
  idempotencyKey: string;
}

function normalizeIdentification(id: PayeeAccountIdentification): PayeeAccountIdentification {
  if (id.type === 'IBAN') {
    return { type: id.type, identification: id.identification.replace(/\s+/g, '').toUpperCase() };
  }
  return id;
}

export function buildPaymentRequest(input: BuildPaymentRequestInput): PaymentRequestPayload {
  const amount = Number((input.amountCents / 100).toFixed(2));

  return {
    type: 'DOMESTIC_PAYMENT',
    paymentIdempotencyId: input.idempotencyKey,
    reference: input.reference.slice(0, 35),
    amount: { amount, currency: input.currency },
    payee: {
      name: input.beneficiaryName.slice(0, 70),
      accountIdentifications: input.payeeIdentifications.map(normalizeIdentification),
    },
  };
}

function maskTail(value: string): string {
  const trimmed = value.replace(/\s+/g, '');
  return trimmed.length <= 4 ? '****' : `****${trimmed.slice(-4)}`;
}

/**
 * Produces a copy of the request safe to persist: sensitive account
 * identifiers (IBAN, account number) are masked so full numbers are never
 * stored in `payment_request_snapshot`. Sort codes are bank routing numbers,
 * not secrets, so they are left intact for support/debugging.
 */
export function redactPaymentRequest(
  request: PaymentRequestPayload,
): PaymentRequestPayload {
  const masked = new Set(['IBAN', 'ACCOUNT_NUMBER', 'BBAN']);
  return {
    ...request,
    payee: {
      ...request.payee,
      accountIdentifications: request.payee.accountIdentifications.map((id) => ({
        type: id.type,
        identification: masked.has(id.type) ? maskTail(id.identification) : id.identification,
      })),
    },
  };
}
