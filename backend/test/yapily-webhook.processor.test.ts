import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { FakePrisma } from './helpers/fake-prisma';
import { YapilyWebhookProcessor } from '../src/infrastructure/queue/yapily-webhook.processor';

function makeJob(payload: Record<string, unknown>, eventId = 'evt-1') {
  return { data: { eventId, eventType: 'payment.status', payload } } as any;
}

function seed(prisma: FakePrisma, paymentStatus = 'AWAITING_AUTHORIZATION') {
  const link = prisma.seedLink({ linkType: 'SINGLE' });
  const payment: any = {
    id: 'pay-1',
    paymentLinkId: link.id,
    yapilyPaymentId: 'yap-1',
    amountCents: 2500,
    currency: 'EUR',
    status: paymentStatus,
    completedAt: null,
  };
  prisma.payments.push(payment);
  prisma.webhookEvents.push({ id: 'we-1', eventId: 'evt-1', processedAt: null });
  return { link, payment };
}

describe('YapilyWebhookProcessor', () => {
  it('completes an in-flight payment and increments link usage', async () => {
    const prisma = new FakePrisma();
    const { link, payment } = seed(prisma);
    const processor = new YapilyWebhookProcessor(prisma as any);

    await processor.process(makeJob({ paymentId: 'yap-1', status: 'COMPLETED' }));

    assert.equal(payment.status, 'COMPLETED');
    assert.equal(link.useCount, 1);
    assert.equal(link.status, 'SETTLED');
    assert.equal(prisma.webhookEvents[0].processedAt !== null, true);
  });

  it('does not double-count when the payment is already COMPLETED', async () => {
    const prisma = new FakePrisma();
    const { link, payment } = seed(prisma, 'COMPLETED');
    link.useCount = 1;
    link.status = 'SETTLED';
    const processor = new YapilyWebhookProcessor(prisma as any);

    await processor.process(makeJob({ paymentId: 'yap-1', status: 'COMPLETED' }));

    assert.equal(payment.status, 'COMPLETED');
    assert.equal(link.useCount, 1, 'useCount must not be incremented twice');
    assert.equal(prisma.webhookEvents[0].processedAt !== null, true);
  });

  it('never treats a missing status as completed', async () => {
    const prisma = new FakePrisma();
    const { link, payment } = seed(prisma);
    const processor = new YapilyWebhookProcessor(prisma as any);

    await processor.process(makeJob({ paymentId: 'yap-1' }));

    assert.equal(payment.status, 'AWAITING_AUTHORIZATION');
    assert.equal(link.useCount, 0);
    assert.equal(prisma.webhookEvents[0].processedAt !== null, true);
  });

  it('marks a failed payment without incrementing usage', async () => {
    const prisma = new FakePrisma();
    const { link, payment } = seed(prisma);
    const processor = new YapilyWebhookProcessor(prisma as any);

    await processor.process(makeJob({ paymentId: 'yap-1', status: 'FAILED' }));

    assert.equal(payment.status, 'FAILED');
    assert.equal(link.useCount, 0);
  });

  it('marks the event processed when no paymentId is present', async () => {
    const prisma = new FakePrisma();
    seed(prisma);
    const processor = new YapilyWebhookProcessor(prisma as any);

    await processor.process(makeJob({ status: 'COMPLETED' }));

    assert.equal(prisma.webhookEvents[0].processedAt !== null, true);
  });
});
