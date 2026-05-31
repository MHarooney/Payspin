import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { SendPushNotificationUseCase } from '../../application/use-cases/notifications/send-push-notification.use-case';

export const NOTIFICATIONS_QUEUE = 'notifications';

export interface PushJob {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Off-thread FCM delivery. Kept separate from the webhook queue so a slow/failing
 * push never blocks settlement processing or the webhook ACK.
 */
@Injectable()
@Processor(NOTIFICATIONS_QUEUE)
export class NotificationProcessor extends WorkerHost {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(private readonly sendPush: SendPushNotificationUseCase) {
    super();
  }

  async process(job: Job<PushJob>): Promise<void> {
    const { userId, title, body, data } = job.data;
    const { sent } = await this.sendPush.execute(userId, { title, body, data });
    this.logger.log(`push ${job.data.data?.type ?? 'generic'} → user=${userId} sent=${sent}`);
  }
}
