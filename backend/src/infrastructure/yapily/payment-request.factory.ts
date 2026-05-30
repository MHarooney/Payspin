import { PaymentRequestPayload } from '@payspin/pisp-provider';

export interface BuildPaymentRequestInput {
  amountCents: number;
  currency: string;
  beneficiaryIban: string;
  beneficiaryName: string;
  reference: string;
  idempotencyKey: string;
}

export function buildPaymentRequest(input: BuildPaymentRequestInput): PaymentRequestPayload {
  const amount = Number((input.amountCents / 100).toFixed(2));
  const normalizedIban = input.beneficiaryIban.replace(/\s+/g, '').toUpperCase();

  return {
    type: input.currency === 'GBP' ? 'DOMESTIC_PAYMENT' : 'DOMESTIC_PAYMENT',
    paymentIdempotencyId: input.idempotencyKey,
    reference: input.reference.slice(0, 35),
    amount: { amount, currency: input.currency },
    payee: {
      name: input.beneficiaryName.slice(0, 70),
      accountIdentifications: [{ type: 'IBAN', identification: normalizedIban }],
    },
  };
}

function maskIban(iban: string): string {
  const normalized = iban.replace(/\s+/g, '');
  return normalized.length <= 4 ? '****' : `****${normalized.slice(-4)}`;
}

/**
 * Produces a copy of the request safe to persist: account identifications are
 * masked so full IBANs are never stored in `payment_request_snapshot`.
 */
export function redactPaymentRequest(
  request: PaymentRequestPayload,
): PaymentRequestPayload {
  return {
    ...request,
    payee: {
      ...request.payee,
      accountIdentifications: request.payee.accountIdentifications.map((id) => ({
        type: id.type,
        identification:
          id.type === 'IBAN' ? maskIban(id.identification) : id.identification,
      })),
    },
  };
}
