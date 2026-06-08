import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { ReconcilePaymentUseCase } from '../../application/use-cases/payments/reconcile-payment.use-case';

export const PAYMENT_RECONCILIATION_QUEUE = 'payment-reconciliation';

@Injectable()
@Processor(PAYMENT_RECONCILIATION_QUEUE)
export class PaymentReconciliationProcessor extends WorkerHost {
  private readonly logger = new Logger(PaymentReconciliationProcessor.name);

  constructor(private readonly reconcile: ReconcilePaymentUseCase) {
    super();
  }

  async process(job: Job<{ kind: 'sweep' }>): Promise<void> {
    if (job.name !== 'sweep') return;
    const result = await this.reconcile.reconcileAllInFlight();
    this.logger.log(
      `Payment sweep: expired=${result.expired} reconciled=${result.reconciled}`,
    );
  }
}
