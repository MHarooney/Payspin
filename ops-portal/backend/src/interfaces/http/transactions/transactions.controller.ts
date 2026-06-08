import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { GetPaymentDetailAdminUseCase } from '../../../application/use-cases/transactions/get-payment-detail-admin.use-case';
import { ListPaymentsAdminUseCase } from '../../../application/use-cases/transactions/list-payments-admin.use-case';
import { RetryPaymentAdminUseCase } from '../../../application/use-cases/transactions/retry-payment-admin.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';

@Controller('transactions')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class TransactionsController {
  constructor(
    private readonly listPayments: ListPaymentsAdminUseCase,
    private readonly getDetail: GetPaymentDetailAdminUseCase,
    private readonly retryPayment: RetryPaymentAdminUseCase,
  ) {}

  @Get()
  list(@Query() query: unknown) {
    return this.listPayments.execute(query);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.getDetail.execute(id);
  }

  @Post(':id/retry')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  retry(@Param('id') id: string, @CurrentAdmin() admin: AdminRequestContext) {
    return this.retryPayment.execute(id, admin);
  }
}
