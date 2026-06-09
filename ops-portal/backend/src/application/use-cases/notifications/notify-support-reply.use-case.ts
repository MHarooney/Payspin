import { InjectQueue } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { NotificationType } from '@payspin/shared-types';
import { Prisma } from '@prisma/client';
import { Queue } from 'bullmq';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { NOTIFICATIONS_QUEUE, PushJob } from '../../../infrastructure/queue/notification.queue';

export interface SupportReplyNotifyInput {
  userId: string;
  threadId: string;
  messageId: string;
  body: string;
}

/**
 * Dual-channel admin-reply notification, mirroring the main backend's
 * NotifyPaymentReceivedUseCase: persists an in-app row (inbox source of truth)
 * and enqueues an FCM push (delivered by the main backend's worker).
 */
@Injectable()
export class NotifySupportReplyUseCase {
  constructor(
    private readonly prisma: PrismaService,
    @InjectQueue(NOTIFICATIONS_QUEUE) private readonly queue: Queue<PushJob>,
  ) {}

  async execute(input: SupportReplyNotifyInput): Promise<void> {
    const title = 'Support replied';
    const body = input.body.length > 120 ? `${input.body.slice(0, 119)}…` : input.body;
    const data = {
      type: NotificationType.SUPPORT_REPLY,
      threadId: input.threadId,
      messageId: input.messageId,
    };

    await this.prisma.notification.create({
      data: {
        userId: input.userId,
        type: NotificationType.SUPPORT_REPLY,
        title,
        body,
        data: data as Prisma.InputJsonValue,
      },
    });

    try {
      await this.queue.add(
        'push',
        { userId: input.userId, title, body, data },
        { removeOnComplete: true, attempts: 3, backoff: { type: 'exponential', delay: 3000 } },
      );
    } catch {
      // Push is best-effort; the in-app row above is the source of truth and the
      // mobile app also polls open threads, so a Redis hiccup never loses a reply.
    }
  }
}
