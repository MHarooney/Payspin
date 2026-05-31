import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { PaymentStatus } from '@payspin/shared-types';
import { FakePrisma } from './helpers/fake-prisma';
import { GetPaymentLinkByShortCodeUseCase } from '../src/application/use-cases/payment-links/get-payment-link-by-short-code.use-case';
import { InitiatePayerPaymentUseCase } from '../src/application/use-cases/payments/initiate-payer-payment.use-case';
import { CompletePayerPaymentUseCase } from '../src/application/use-cases/payments/complete-payer-payment.use-case';
import { GetPaymentStatusUseCase } from '../src/application/use-cases/payments/get-payment-status.use-case';

const TEST_IBAN = 'NL91ABNA0417164300';

const config = { get: () => 'http://localhost:3000' } as any;
const decryptedIban = { execute: async () => TEST_IBAN } as any;
const pisGateway = {
  createPaymentAuthRequest: async ({ callbackUrl }: { callbackUrl: string }) => ({
    authRequestId: 'auth-1',
    authorisationUrl: `${callbackUrl}?sandboxPending=auth-1`,
  }),
  createPayment: async () => ({ paymentId: 'yap-1', status: PaymentStatus.COMPLETED }),
  getPaymentStatus: async () => PaymentStatus.COMPLETED,
  verifyWebhookSignature: () => true,
} as any;

function build(prisma: FakePrisma) {
  const getLink = new GetPaymentLinkByShortCodeUseCase(prisma as any);
  const initiate = new InitiatePayerPaymentUseCase(
    prisma as any,
    getLink,
    decryptedIban,
    config,
    pisGateway,
  );
  const notifyPaymentReceived = { execute: async () => {} } as any;
  const complete = new CompletePayerPaymentUseCase(
    prisma as any,
    getLink,
    decryptedIban,
    pisGateway,
    notifyPaymentReceived,
  );
  const status = new GetPaymentStatusUseCase(prisma as any, getLink);
  return { getLink, initiate, complete, status };
}

describe('payment link lifecycle', () => {
  it('SINGLE: completes once, settles link, blocks a second in-flight payment', async () => {
    const prisma = new FakePrisma();
    const link = prisma.seedLink({ shortCode: 'single1', linkType: 'SINGLE' });
    const { initiate, complete } = build(prisma);

    const init = await initiate.execute('single1');
    await assert.rejects(
      () => initiate.execute('single1'),
      /already has a payment/,
    );

    const res = await complete.execute('single1', {
      paymentId: init.paymentId,
      consentToken: 'token',
    });
    assert.equal(res.status, PaymentStatus.COMPLETED);
    assert.equal(link.status, 'SETTLED');
    assert.equal(link.useCount, 1);
  });

  it('SINGLE: double completion does not double-count', async () => {
    const prisma = new FakePrisma();
    const link = prisma.seedLink({ shortCode: 'single2', linkType: 'SINGLE' });
    const { initiate, complete } = build(prisma);

    const init = await initiate.execute('single2');
    await complete.execute('single2', { paymentId: init.paymentId, consentToken: 't' });

    await assert.rejects(
      () => complete.execute('single2', { paymentId: init.paymentId, consentToken: 't' }),
      /not active|already completed/,
    );
    assert.equal(link.useCount, 1);
  });

  it('MULTI: accepts payments up to maxUses then settles', async () => {
    const prisma = new FakePrisma();
    const link = prisma.seedLink({
      shortCode: 'multi1',
      linkType: 'MULTI',
      maxUses: 2,
      amountCents: 1000,
    });
    const { initiate, complete } = build(prisma);

    const i1 = await initiate.execute('multi1');
    await complete.execute('multi1', { paymentId: i1.paymentId, consentToken: 't' });
    assert.equal(link.useCount, 1);
    assert.equal(link.status, 'COLLECTING');

    const i2 = await initiate.execute('multi1');
    await complete.execute('multi1', { paymentId: i2.paymentId, consentToken: 't' });
    assert.equal(link.useCount, 2);
    assert.equal(link.status, 'SETTLED');

    await assert.rejects(() => initiate.execute('multi1'), /maximum uses|not active/);
  });

  it('MULTI: blocks a second in-flight initiation that would exceed maxUses', async () => {
    // Regression guard for the initiate race: with maxUses=1 and one payment
    // already AWAITING_AUTHORIZATION (not yet completed, so useCount is still
    // 0), a concurrent initiate must be rejected by the in-transaction count.
    const prisma = new FakePrisma();
    prisma.seedLink({
      shortCode: 'multicap',
      linkType: 'MULTI',
      maxUses: 1,
      amountCents: 1000,
    });
    const { initiate } = build(prisma);

    await initiate.execute('multicap');
    await assert.rejects(
      () => initiate.execute('multicap'),
      /maximum uses|in progress/,
    );
    const active = prisma.payments.filter(
      (p) => p.status === 'AWAITING_AUTHORIZATION',
    );
    assert.equal(active.length, 1, 'only one in-flight payment may exist');
  });

  it('MULTI: blocks initiation once maxUses reached while collecting', async () => {
    const prisma = new FakePrisma();
    prisma.seedLink({
      shortCode: 'multi2',
      linkType: 'MULTI',
      maxUses: 2,
      useCount: 2,
      status: 'COLLECTING',
    });
    const { initiate } = build(prisma);
    await assert.rejects(() => initiate.execute('multi2'), /maximum uses/);
  });

  it('expired links are blocked and lazily marked EXPIRED', async () => {
    const prisma = new FakePrisma();
    const link = prisma.seedLink({
      shortCode: 'exp1',
      expiresAt: new Date(Date.now() - 1000),
    });
    const { initiate } = build(prisma);
    await assert.rejects(() => initiate.execute('exp1'), /expired/);
    assert.equal(link.status, 'EXPIRED');
  });

  it('cancelled links are blocked', async () => {
    const prisma = new FakePrisma();
    prisma.seedLink({ shortCode: 'can1', status: 'CANCELLED' });
    const { initiate } = build(prisma);
    await assert.rejects(() => initiate.execute('can1'), /not active/);
  });

  it('open-amount links require a payer amount', async () => {
    const prisma = new FakePrisma();
    prisma.seedLink({ shortCode: 'open1', amountCents: null });
    const { initiate } = build(prisma);
    await assert.rejects(() => initiate.execute('open1'), /Amount is required/);
    const ok = await initiate.execute('open1', { amountCents: 500 });
    assert.ok(ok.paymentId);
  });

  it('status polling still works after a SINGLE link settles', async () => {
    const prisma = new FakePrisma();
    prisma.seedLink({ shortCode: 'single3', linkType: 'SINGLE' });
    const { initiate, complete, status } = build(prisma);

    const init = await initiate.execute('single3');
    await complete.execute('single3', { paymentId: init.paymentId, consentToken: 't' });

    const polled = await status.execute('single3', init.paymentId);
    assert.equal(polled.status, PaymentStatus.COMPLETED);
  });

  it('never persists a plaintext IBAN in the payment snapshot', async () => {
    const prisma = new FakePrisma();
    prisma.seedLink({ shortCode: 'redact1' });
    const { initiate } = build(prisma);
    const init = await initiate.execute('redact1');
    const payment = prisma.payments.find((p) => p.id === init.paymentId)!;
    const serialized = JSON.stringify(payment.paymentRequestSnapshot);
    assert.ok(serialized.includes('****'), 'snapshot should mask the IBAN');
    assert.ok(!serialized.includes(TEST_IBAN), 'snapshot must not contain the full IBAN');
  });
});
