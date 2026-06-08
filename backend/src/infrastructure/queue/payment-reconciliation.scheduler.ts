import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PAYMENT_RECONCILIATION_QUEUE } from './payment-reconciliation.processor';

const SWEEP_INTERVAL_MS = Number(process.env.PAYMENT_SWEEP_INTERVAL_MS ?? 900_000);

@Injectable()
export class PaymentReconciliationScheduler implements OnModuleInit {
  private readonly logger = new Logger(PaymentReconciliationScheduler.name);

  constructor(
    @InjectQueue(PAYMENT_RECONCILIATION_QUEUE) private readonly queue: Queue,
  ) {}

  async onModuleInit() {
    await this.queue.add(
      'sweep',
      { kind: 'sweep' },
      {
        jobId: 'payment-reconciliation-sweep',
        repeat: { every: SWEEP_INTERVAL_MS },
        removeOnComplete: true,
        removeOnFail: false,
      },
    );
    this.logger.log(`Scheduled payment reconciliation every ${SWEEP_INTERVAL_MS}ms`);
  }
}
