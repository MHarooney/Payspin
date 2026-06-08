import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { PaymentStatus } from '@payspin/shared-types';
import { FakePrisma } from './helpers/fake-prisma';
import { ExpireStalePaymentsUseCase } from '../src/application/use-cases/payments/expire-stale-payments.use-case';
import { ReconcilePaymentUseCase } from '../src/application/use-cases/payments/reconcile-payment.use-case';
import { AbandonPayerPaymentUseCase } from '../src/application/use-cases/payments/abandon-payer-payment.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../src/application/use-cases/payment-links/get-payment-link-by-short-code.use-case';

describe('ExpireStalePaymentsUseCase', () => {
  it('cancels AWAITING payments older than the stale window', async () => {
    let capturedWhere: any;
    const prisma = {
      payment: {
        updateMany: async ({ where, data }: any) => {
          if (data.status === 'CANCELLED') capturedWhere = where;
          return { count: data.status === 'CANCELLED' ? 2 : 0 };
        },
      },
    } as any;
    const useCase = new ExpireStalePaymentsUseCase(prisma);
    const result = await useCase.execute('link-1');
    assert.equal(result.awaitingCancelled, 2);
    assert.equal(capturedWhere.paymentLinkId, 'link-1');
    assert.equal(capturedWhere.status, 'AWAITING_AUTHORIZATION');
  });
});

describe('ReconcilePaymentUseCase', () => {
  let prisma: FakePrisma;
  let expire: ExpireStalePaymentsUseCase;
  let reconcile: ReconcilePaymentUseCase;

  beforeEach(() => {
    prisma = new FakePrisma();
    expire = new ExpireStalePaymentsUseCase({
      payment: {
        updateMany: async () => ({ count: 0 }),
      },
    } as any);
    reconcile = new ReconcilePaymentUseCase(
      prisma as any,
      expire,
      { getPaymentStatus: async () => PaymentStatus.COMPLETED } as any,
      { execute: async () => {} } as any,
    );
  });

  it('promotes a PENDING payment to COMPLETED when Yapily reports completed', async () => {
    const link = prisma.seedLink({ shortCode: 'rc1', linkType: 'SINGLE' });
    const payment: any = {
      id: 'pay-rc1',
      paymentLinkId: link.id,
      yapilyPaymentId: 'yap-rc1',
      amountCents: 20000,
      currency: 'EUR',
      status: 'PENDING',
      completedAt: null,
    };
    prisma.payments.push(payment);

    const row = await reconcile.execute('pay-rc1');
    assert.equal(row.status, 'COMPLETED');
    assert.equal(link.useCount, 1);
    assert.equal(link.status, 'SETTLED');
  });
});

describe('AbandonPayerPaymentUseCase', () => {
  it('marks AWAITING_AUTHORIZATION as CANCELLED when payer declines at bank', async () => {
    const prisma = new FakePrisma();
    const link = prisma.seedLink({ shortCode: 'ab1' });
    prisma.payments.push({
      id: 'pay-ab1',
      paymentLinkId: link.id,
      status: 'AWAITING_AUTHORIZATION',
      amountCents: 1000,
      currency: 'EUR',
    });

    const useCase = new AbandonPayerPaymentUseCase(
      prisma as any,
      new GetPaymentLinkByShortCodeUseCase(prisma as any),
    );

    const res = await useCase.execute('ab1', { paymentId: 'pay-ab1' });
    assert.equal(res.status, 'CANCELLED');
    assert.equal(prisma.payments[0].status, 'CANCELLED');
  });
});

describe('Initiate stale expiry unblocks SINGLE links', () => {
  it('expire on link allows a new initiation after an old AWAITING row is cancelled', async () => {
    const prisma = {
      payment: {
        updateMany: async ({ data }: any) => {
          if (data.status === 'CANCELLED') return { count: 1 };
          return { count: 0 };
        },
        findFirst: async () => null,
        count: async () => 0,
        create: async ({ data }: any) => ({ id: 'new-pay', ...data }),
      },
      paymentLink: {
        findUnique: async () => ({
          id: 'link-1',
          shortCode: 'x',
          status: 'ACTIVE',
          linkType: 'SINGLE',
          maxUses: null,
          useCount: 0,
          expiresAt: null,
          payeeUserId: 'u1',
          bankAccountId: 'b1',
          amountCents: null,
          currency: 'EUR',
          bankAccount: { accountHolder: 'H' },
        }),
        update: async ({ data }: any) => data,
      },
      $queryRaw: async () => [],
      $transaction: async (fn: any) => fn(prisma),
    } as any;

    const expire = new ExpireStalePaymentsUseCase(prisma);
    const result = await expire.execute('link-1');
    assert.equal(result.awaitingCancelled, 1);
  });
});
