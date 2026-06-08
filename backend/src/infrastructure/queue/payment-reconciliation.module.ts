import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ReconcilePaymentUseCase } from '../../application/use-cases/payments/reconcile-payment.use-case';
import { ExpireStalePaymentsUseCase } from '../../application/use-cases/payments/expire-stale-payments.use-case';
import { PAYMENT_RECONCILIATION_QUEUE } from './payment-reconciliation.processor';
import { PaymentReconciliationProcessor } from './payment-reconciliation.processor';
import { PaymentReconciliationScheduler } from './payment-reconciliation.scheduler';
import { YapilyModule } from '../yapily/yapily.module';
import { NotificationsModule } from '../../interfaces/http/notifications/notifications.module';

@Module({
  imports: [
    YapilyModule,
    NotificationsModule,
    BullModule.registerQueue({ name: PAYMENT_RECONCILIATION_QUEUE }),
  ],
  providers: [
    ExpireStalePaymentsUseCase,
    ReconcilePaymentUseCase,
    PaymentReconciliationProcessor,
    PaymentReconciliationScheduler,
  ],
  exports: [ExpireStalePaymentsUseCase, ReconcilePaymentUseCase],
})
export class PaymentReconciliationModule {}
