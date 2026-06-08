import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { AdminWebhookDetail, AdminWebhookListItem, Paginated } from '@payspin/shared-types';
import { ListWebhooksAdminUseCase } from '../../../application/use-cases/webhooks/list-webhooks-admin.use-case';
import { GetWebhookDetailAdminUseCase } from '../../../application/use-cases/webhooks/get-webhook-detail-admin.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';

@Controller('webhooks')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class WebhooksController {
  constructor(
    private readonly list: ListWebhooksAdminUseCase,
    private readonly getDetail: GetWebhookDetailAdminUseCase,
  ) {}

  @Get()
  listAll(@Query() query: unknown): Promise<Paginated<AdminWebhookListItem>> {
    return this.list.execute(query);
  }

  @Get(':id')
  detail(@Param('id') id: string, @CurrentAdmin() admin: AdminRequestContext): Promise<AdminWebhookDetail> {
    return this.getDetail.execute(id, admin);
  }
}
