import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { CreatePaymentLinkAdminUseCase } from '../../../application/use-cases/payment-links/create-payment-link-admin.use-case';
import { GetPaymentLinkDetailAdminUseCase, PatchPaymentLinkAdminUseCase } from '../../../application/use-cases/payment-links/payment-link-admin.use-case';
import { ListPaymentLinksAdminUseCase } from '../../../application/use-cases/payment-links/list-payment-links-admin.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';

@Controller('payment-links')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class PaymentLinksController {
  constructor(
    private readonly list: ListPaymentLinksAdminUseCase,
    private readonly getDetail: GetPaymentLinkDetailAdminUseCase,
    private readonly patch: PatchPaymentLinkAdminUseCase,
    private readonly create: CreatePaymentLinkAdminUseCase,
  ) {}

  @Get()
  listAll(@Query() query: unknown) {
    return this.list.execute(query);
  }

  @Post()
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  createLink(@Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    return this.create.execute(body, admin);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.getDetail.execute(id);
  }

  @Patch(':id')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  update(@Param('id') id: string, @Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    return this.patch.execute(id, body, admin);
  }
}
