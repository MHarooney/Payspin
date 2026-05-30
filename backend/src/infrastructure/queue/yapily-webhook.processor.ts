import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { PaymentLinkStatus, PaymentStatus } from '@prisma/client';
import { Job } from 'bullmq';
import { PrismaService } from '../persistence/prisma.module';

export const YAPILY_WEBHOOK_QUEUE = 'yapily-webhooks';

export interface YapilyWebhookJob {
  eventId: string;
  eventType: string;
  payload: Record<string, unknown>;
}

@Injectable()
@Processor(YAPILY_WEBHOOK_QUEUE)
export class YapilyWebhookProcessor extends WorkerHost {
  constructor(private readonly prisma: PrismaService) {
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

    await this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.findFirst({
        where: {
          OR: [{ yapilyPaymentId: paymentId }, { id: paymentId }],
        },
        include: { paymentLink: true },
      });
      if (!payment) return;

      const statusRaw = String(
        (payload.status as string | undefined) ??
          (payload.data as { status?: string } | undefined)?.status ??
          'COMPLETED',
      ).toUpperCase();

      const isCompleted =
        statusRaw.includes('COMPLETED') || statusRaw.includes('ACCEPTED');
      const isFailed = statusRaw.includes('FAILED') || statusRaw.includes('REJECTED');

      if (!isCompleted && !isFailed) return;

      await tx.payment.update({
        where: { id: payment.id },
        data: {
          status: isCompleted ? PaymentStatus.COMPLETED : PaymentStatus.FAILED,
          completedAt: isCompleted ? new Date() : null,
          webhookRaw: payload as object,
        },
      });

      if (isCompleted) {
        await tx.paymentLink.update({
          where: { id: payment.paymentLinkId },
          data: {
            useCount: { increment: 1 },
            status:
              payment.paymentLink.linkType === 'SINGLE'
                ? PaymentLinkStatus.SETTLED
                : PaymentLinkStatus.COLLECTING,
          },
        });
      }

      await tx.webhookEvent.update({
        where: { eventId },
        data: { processedAt: new Date() },
      });
    });
  }
}
