import { Module } from '@nestjs/common';
import { CancelPaymentLinkUseCase } from '../../../application/use-cases/payment-links/cancel-payment-link.use-case';
import { CreatePaymentLinkUseCase } from '../../../application/use-cases/payment-links/create-payment-link.use-case';
import { GetDefaultBankAccountUseCase } from '../../../application/use-cases/payment-links/get-default-bank-account.use-case';
import { GetPaymentLinkByIdUseCase } from '../../../application/use-cases/payment-links/get-payment-link-by-id.use-case';
import { GetPaymentLinkByShortCodeUseCase } from '../../../application/use-cases/payment-links/get-payment-link-by-short-code.use-case';
import { ListPaymentLinksUseCase } from '../../../application/use-cases/payment-links/list-payment-links.use-case';
import { PaymentLinkStatsUseCase } from '../../../application/use-cases/payment-links/payment-link-stats.use-case';
import { PaymentLinksMapper } from '../../../application/use-cases/payment-links/payment-links.mapper';
import { BankAccountsModule } from '../bank-accounts/bank-accounts.module';
import { PaymentLinksController } from './payment-links.controller';

@Module({
  imports: [BankAccountsModule],
  controllers: [PaymentLinksController],
  providers: [
    PaymentLinksMapper,
    PaymentLinkStatsUseCase,
    GetDefaultBankAccountUseCase,
    CreatePaymentLinkUseCase,
    ListPaymentLinksUseCase,
    GetPaymentLinkByIdUseCase,
    CancelPaymentLinkUseCase,
    GetPaymentLinkByShortCodeUseCase,
  ],
  exports: [GetPaymentLinkByShortCodeUseCase],
})
export class PaymentLinksModule {}
