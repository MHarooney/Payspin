import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { buildPaymentRequest } from '../src/infrastructure/yapily/payment-request.factory';

describe('buildPaymentRequest', () => {
  it('normalizes IBAN and formats EUR amount', () => {
    const req = buildPaymentRequest({
      amountCents: 1250,
      currency: 'EUR',
      beneficiaryIban: 'nl91 abna 0417 1643 00',
      beneficiaryName: 'Payee Name',
      reference: 'Test payment',
      idempotencyKey: 'idem-1',
    });

    assert.equal(req.amount.amount, 12.5);
    assert.equal(req.amount.currency, 'EUR');
    assert.equal(req.payee.accountIdentifications[0].identification, 'NL91ABNA0417164300');
    assert.equal(req.paymentIdempotencyId, 'idem-1');
  });
});
