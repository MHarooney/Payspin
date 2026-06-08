import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { buildPaymentRequest } from '../src/infrastructure/yapily/payment-request.factory';

describe('buildPaymentRequest', () => {
  it('normalizes IBAN and formats EUR amount', () => {
    const req = buildPaymentRequest({
      amountCents: 1250,
      currency: 'EUR',
      payeeIdentifications: [{ type: 'IBAN', identification: 'nl91 abna 0417 1643 00' }],
      beneficiaryName: 'Payee Name',
      reference: 'Test payment',
      idempotencyKey: 'idem-1',
    });

    assert.equal(req.amount.amount, 12.5);
    assert.equal(req.amount.currency, 'EUR');
    assert.equal(req.payee.accountIdentifications[0].identification, 'NL91ABNA0417164300');
    assert.equal(req.paymentIdempotencyId, 'idem-1');
  });

  it('passes through UK SORT_CODE + ACCOUNT_NUMBER unchanged', () => {
    const req = buildPaymentRequest({
      amountCents: 5000,
      currency: 'GBP',
      payeeIdentifications: [
        { type: 'SORT_CODE', identification: '100001' },
        { type: 'ACCOUNT_NUMBER', identification: '09010103' },
      ],
      beneficiaryName: 'Payee Name',
      reference: 'Test payment',
      idempotencyKey: 'idem-2',
    });

    assert.equal(req.amount.currency, 'GBP');
    assert.deepEqual(req.payee.accountIdentifications, [
      { type: 'SORT_CODE', identification: '100001' },
      { type: 'ACCOUNT_NUMBER', identification: '09010103' },
    ]);
  });
});
