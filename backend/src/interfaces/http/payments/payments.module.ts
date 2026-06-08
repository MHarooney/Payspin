import { Module } from '@nestjs/common';
import { YapilyModule } from '../../../infrastructure/yapily/yapily.module';
import { PaymentReconciliationModule } from '../../../infrastructure/queue/payment-reconciliation.module';
import { CompletePayerPaymentUseCase } from '../../../application/use-cases/payments/complete-payer-payment.use-case';
import { GetPaymentStatusUseCase } from '../../../application/use-cases/payments/get-payment-status.use-case';
import { GetPublicPaymentViewUseCase } from '../../../application/use-cases/payments/get-public-payment-view.use-case';
import { InitiatePayerPaymentUseCase } from '../../../application/use-cases/payments/initiate-payer-payment.use-case';
import { AbandonPayerPaymentUseCase } from '../../../application/use-cases/payments/abandon-payer-payment.use-case';
import { BankAccountsModule } from '../bank-accounts/bank-accounts.module';
import { PaymentLinksModule } from '../payment-links/payment-links.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PaymentsController } from './payments.controller';
import { InternalPaymentsController } from './internal-payments.controller';

@Module({
  imports: [
    YapilyModule,
    PaymentReconciliationModule,
    PaymentLinksModule,
    BankAccountsModule,
    NotificationsModule,
  ],
  controllers: [PaymentsController, InternalPaymentsController],
  providers: [
    GetPublicPaymentViewUseCase,
    InitiatePayerPaymentUseCase,
    CompletePayerPaymentUseCase,
    GetPaymentStatusUseCase,
    AbandonPayerPaymentUseCase,
  ],
})
export class PaymentsModule {}
