import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { PaymentStatus } from '@payspin/shared-types';
import { FakePrisma } from './helpers/fake-prisma';
import { GetPaymentStatusUseCase } from '../src/application/use-cases/payments/get-payment-status.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../src/application/use-cases/payment-links/get-payment-link-by-short-code.use-case';
import { ReconcilePaymentUseCase } from '../src/application/use-cases/payments/reconcile-payment.use-case';
import { ExpireStalePaymentsUseCase } from '../src/application/use-cases/payments/expire-stale-payments.use-case';

describe('GetPaymentStatusUseCase', () => {
  it('reconciles PENDING payments with Yapily on poll', async () => {
    const prisma = new FakePrisma();
    const link = prisma.seedLink({ shortCode: 'poll1', linkType: 'SINGLE' });
    const payment: any = {
      id: 'pay-poll',
      paymentLinkId: link.id,
      yapilyPaymentId: 'yap-poll',
      amountCents: 500,
      currency: 'EUR',
      status: 'PENDING',
      completedAt: null,
    };
    prisma.payments.push(payment);

    const expire = new ExpireStalePaymentsUseCase({
      payment: { updateMany: async () => ({ count: 0 }) },
    } as any);
    const reconcile = new ReconcilePaymentUseCase(
      prisma as any,
      expire,
      { getPaymentStatus: async () => PaymentStatus.COMPLETED } as any,
      { execute: async () => {} } as any,
    );
    const getLink = new GetPaymentLinkByShortCodeUseCase(prisma as any);
    const status = new GetPaymentStatusUseCase(prisma as any, getLink, reconcile);

    const res = await status.execute('poll1', 'pay-poll');

    assert.equal(res.status, PaymentStatus.COMPLETED);
    assert.equal(payment.status, 'COMPLETED');
    assert.equal(link.useCount, 1);
    assert.equal(link.status, 'SETTLED');
  });

  it('returns cached status when Yapily is still pending', async () => {
    const prev = process.env.PAYSPIN_SANDBOX_AUTO_SETTLE;
    process.env.PAYSPIN_SANDBOX_AUTO_SETTLE = 'false';
    const prisma = new FakePrisma();
    prisma.seedLink({ shortCode: 'poll2', linkType: 'SINGLE' });
    const payment: any = {
      id: 'pay-pending',
      paymentLinkId: prisma.paymentLinks[0].id,
      yapilyPaymentId: 'yap-pending',
      amountCents: 500,
      currency: 'EUR',
      status: 'PENDING',
      completedAt: null,
    };
    prisma.payments.push(payment);

    const expire = new ExpireStalePaymentsUseCase({
      payment: { updateMany: async () => ({ count: 0 }) },
    } as any);
    const reconcile = new ReconcilePaymentUseCase(
      prisma as any,
      expire,
      { getPaymentStatus: async () => PaymentStatus.PENDING } as any,
      { execute: async () => {} } as any,
    );
    const getLink = new GetPaymentLinkByShortCodeUseCase(prisma as any);
    const status = new GetPaymentStatusUseCase(prisma as any, getLink, reconcile);

    const res = await status.execute('poll2', 'pay-pending');
    assert.equal(res.status, PaymentStatus.PENDING);
    assert.equal(payment.status, 'PENDING');
    if (prev === undefined) delete process.env.PAYSPIN_SANDBOX_AUTO_SETTLE;
    else process.env.PAYSPIN_SANDBOX_AUTO_SETTLE = prev;
  });

  it('auto-settles sandbox pending payments on poll', async () => {
    const prev = process.env.PAYSPIN_SANDBOX_AUTO_SETTLE;
    process.env.PAYSPIN_SANDBOX_AUTO_SETTLE = 'true';

    const prisma = new FakePrisma();
    const link = prisma.seedLink({ shortCode: 'poll3', linkType: 'SINGLE' });
    const payment: any = {
      id: 'pay-sandbox',
      paymentLinkId: link.id,
      yapilyPaymentId: 'yap-sandbox',
      amountCents: 500,
      currency: 'EUR',
      status: 'PENDING',
      completedAt: null,
    };
    prisma.payments.push(payment);

    const expire = new ExpireStalePaymentsUseCase({
      payment: { updateMany: async () => ({ count: 0 }) },
    } as any);
    const reconcile = new ReconcilePaymentUseCase(
      prisma as any,
      expire,
      { getPaymentStatus: async () => PaymentStatus.PENDING } as any,
      { execute: async () => {} } as any,
    );
    const getLink = new GetPaymentLinkByShortCodeUseCase(prisma as any);
    const status = new GetPaymentStatusUseCase(prisma as any, getLink, reconcile);

    const res = await status.execute('poll3', 'pay-sandbox');
    assert.equal(res.status, PaymentStatus.COMPLETED);
    assert.equal(payment.status, 'COMPLETED');

    if (prev === undefined) delete process.env.PAYSPIN_SANDBOX_AUTO_SETTLE;
    else process.env.PAYSPIN_SANDBOX_AUTO_SETTLE = prev;
  });
});
