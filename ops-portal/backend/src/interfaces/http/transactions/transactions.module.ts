import { Module } from '@nestjs/common';
import { GetPaymentDetailAdminUseCase } from '../../../application/use-cases/transactions/get-payment-detail-admin.use-case';
import { ListPaymentsAdminUseCase } from '../../../application/use-cases/transactions/list-payments-admin.use-case';
import { RefreshPaymentAdminUseCase } from '../../../application/use-cases/transactions/refresh-payment-admin.use-case';
import { RetryPaymentAdminUseCase } from '../../../application/use-cases/transactions/retry-payment-admin.use-case';
import { TransactionsMapper } from '../../../application/use-cases/transactions/transactions.mapper';
import { TransactionsController } from './transactions.controller';

@Module({
  controllers: [TransactionsController],
  providers: [
    ListPaymentsAdminUseCase,
    GetPaymentDetailAdminUseCase,
    RetryPaymentAdminUseCase,
    RefreshPaymentAdminUseCase,
    TransactionsMapper,
  ],
})
export class TransactionsModule {}
