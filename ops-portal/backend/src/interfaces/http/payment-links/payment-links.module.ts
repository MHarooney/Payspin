import { Module } from '@nestjs/common';
import { GetPaymentLinkDetailAdminUseCase, PatchPaymentLinkAdminUseCase } from '../../../application/use-cases/payment-links/payment-link-admin.use-case';
import { ListPaymentLinksAdminUseCase } from '../../../application/use-cases/payment-links/list-payment-links-admin.use-case';
import { PaymentLinksController } from './payment-links.controller';

@Module({
  controllers: [PaymentLinksController],
  providers: [ListPaymentLinksAdminUseCase, GetPaymentLinkDetailAdminUseCase, PatchPaymentLinkAdminUseCase],
})
export class PaymentLinksModule {}
