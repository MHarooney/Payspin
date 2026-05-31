import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Injectable, Optional } from '@nestjs/common';
import { PaymentStatus } from '@prisma/client';
import { Job } from 'bullmq';
import { nextStatusAfterPayment } from '../../domain/utils/payment-link-state';
import { NotifyPaymentReceivedUseCase } from '../../application/use-cases/notifications/notify-payment-received.use-case';
import { PrismaService } from '../persistence/prisma.module';

export const YAPILY_WEBHOOK_QUEUE = 'yapily-webhooks';

export interface YapilyWebhookJob {
  eventId: string;
  eventType: string;
  payload: Record<string, unknown>;
}

interface SettledPayment {
  paymentId: string;
  payeeUserId: string;
  linkId: string;
  amountCents: number;
  currency: string;
}

@Injectable()
@Processor(YAPILY_WEBHOOK_QUEUE)
export class YapilyWebhookProcessor extends WorkerHost {
  // Optional so existing unit tests that construct the processor with only a
  // Prisma double keep working (notifications are best-effort, never blocking).
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly notifyPaymentReceived?: NotifyPaymentReceivedUseCase,
  ) {
    super();
  }

  async process(job: Job<YapilyWebhookJob>): Promise<void> {
    const { eventId, payload } = job.data;
    const paymentId =
      (payload.paymentId as string | undefined) ??
      (payload.data as { id?: string; paymentId?: string } | undefined)?.id ??
      (payload.data as { paymentId?: string } | undefined)?.paymentId;

    if (!paymentId) {
      await this.prisma.webhookEvent.update({
        where: { eventId },
        data: { processedAt: new Date() },
      });
      return;
    }

    let settled: SettledPayment | null = null;

    await this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.findFirst({
        where: {
          OR: [{ yapilyPaymentId: paymentId }, { id: paymentId }],
        },
        include: { paymentLink: true },
      });

      if (payment) {
        // Default to UNKNOWN — a missing/garbled status must never be treated
        // as a successful payment.
        const statusRaw = String(
          (payload.status as string | undefined) ??
            (payload.data as { status?: string } | undefined)?.status ??
            'UNKNOWN',
        ).toUpperCase();

        const isCompleted =
          statusRaw.includes('COMPLETED') || statusRaw.includes('ACCEPTED');
        const isFailed =
          statusRaw.includes('FAILED') || statusRaw.includes('REJECTED');

        if (isCompleted || isFailed) {
          // Only transition payments that are still in flight, so a webhook
          // that races the payer callback cannot double-count link usage.
          const transition = await tx.payment.updateMany({
            where: {
              id: payment.id,
              status: {
                in: [
                  PaymentStatus.AWAITING_AUTHORIZATION,
                  PaymentStatus.PENDING,
                  PaymentStatus.PROCESSING,
                ],
              },
            },
            data: {
              status: isCompleted ? PaymentStatus.COMPLETED : PaymentStatus.FAILED,
              completedAt: isCompleted ? new Date() : null,
              webhookRaw: payload as object,
            },
          });

          if (transition.count === 1 && isCompleted) {
            await tx.paymentLink.update({
              where: { id: payment.paymentLinkId },
              data: {
                useCount: { increment: 1 },
                status: nextStatusAfterPayment(payment.paymentLink),
              },
            });

            settled = {
              paymentId: payment.id,
              payeeUserId: payment.paymentLink.payeeUserId,
              linkId: payment.paymentLinkId,
              amountCents: payment.amountCents,
              currency: payment.currency,
            };
          }
        }
      }

      await tx.webhookEvent.update({
        where: { eventId },
        data: { processedAt: new Date() },
      });
    });

    // Notify outside the DB transaction so a push/queue hiccup can't roll back a
    // committed settlement. Only fires on the single winning COMPLETED transition.
    if (settled && this.notifyPaymentReceived) {
      await this.notifyPaymentReceived.execute(settled);
    }
  }
}
