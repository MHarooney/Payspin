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
