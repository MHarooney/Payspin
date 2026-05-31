import { InjectQueue } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { NotificationType } from '@payspin/shared-types';
import { Queue } from 'bullmq';
import {
  NOTIFICATIONS_QUEUE,
  PushJob,
} from '../../../infrastructure/queue/notification.processor';
import { CreateNotificationUseCase } from './create-notification.use-case';

export interface PaymentReceivedInput {
  payeeUserId: string;
  paymentId: string;
  linkId: string;
  amountCents: number;
  currency: string;
}

const CURRENCY_SYMBOLS: Record<string, string> = { EUR: '€', GBP: '£', USD: '$' };

function formatAmount(amountCents: number, currency: string): string {
  const symbol = CURRENCY_SYMBOLS[currency.toUpperCase()] ?? `${currency} `;
  return `${symbol}${(amountCents / 100).toFixed(2)}`;
}

/**
 * Dual-channel payment-received notification: persists an in-app row (the inbox
 * source of truth) and enqueues an FCM push (the realtime "refresh" signal).
 */
@Injectable()
export class NotifyPaymentReceivedUseCase {
  constructor(
    private readonly createNotification: CreateNotificationUseCase,
    @InjectQueue(NOTIFICATIONS_QUEUE) private readonly queue: Queue<PushJob>,
  ) {}

  async execute(input: PaymentReceivedInput): Promise<void> {
    const amount = formatAmount(input.amountCents, input.currency);
    const title = 'Payment received';
    const body = `${amount} received`;
    const data = {
      type: NotificationType.PAYMENT_RECEIVED,
      paymentId: input.paymentId,
      linkId: input.linkId,
      amountCents: String(input.amountCents),
      currency: input.currency,
    };

    await this.createNotification.execute({
      userId: input.payeeUserId,
      type: NotificationType.PAYMENT_RECEIVED,
      title,
      body,
      data,
    });

    await this.queue.add(
      'push',
      { userId: input.payeeUserId, title, body, data },
      { removeOnComplete: true, attempts: 3, backoff: { type: 'exponential', delay: 3000 } },
    );
  }
}
