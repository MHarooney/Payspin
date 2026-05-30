import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { SandboxPisGateway } from '../src/infrastructure/yapily/sandbox-pis.gateway';
import { PaymentStatus } from '@payspin/shared-types';

describe('SandboxPisGateway', () => {
  const gateway = new SandboxPisGateway();

  it('creates auth URL with sandbox pending marker', async () => {
    const result = await gateway.createPaymentAuthRequest({
      applicationUserId: 'user-1',
      callbackUrl: 'http://localhost:3000/abc/callback?paymentId=pay-1',
      paymentRequest: {
        type: 'DOMESTIC_PAYMENT',
        paymentIdempotencyId: 'idem-1',
        reference: 'ref',
        amount: { amount: 10, currency: 'EUR' },
        payee: {
          name: 'Payee',
          accountIdentifications: [{ type: 'IBAN', identification: 'NL91ABNA0417164300' }],
        },
      },
    });

    assert.ok(result.authorisationUrl.includes('sandboxPending'));
    assert.ok(result.authRequestId.startsWith('sandbox_auth_'));
  });

  it('completes payment as COMPLETED in sandbox', async () => {
    const result = await gateway.createPayment({
      consentToken: 'any',
      idempotencyKey: 'idem-2',
      paymentRequest: {
        type: 'DOMESTIC_PAYMENT',
        paymentIdempotencyId: 'idem-2',
        reference: 'ref',
        amount: { amount: 5, currency: 'EUR' },
        payee: {
          name: 'Payee',
          accountIdentifications: [{ type: 'IBAN', identification: 'NL91ABNA0417164300' }],
        },
      },
    });

    assert.equal(result.status, PaymentStatus.COMPLETED);
    assert.ok(result.paymentId.startsWith('sandbox_'));
  });
});
