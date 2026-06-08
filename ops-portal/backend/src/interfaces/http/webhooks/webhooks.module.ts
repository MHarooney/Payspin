import { Module } from '@nestjs/common';
import { ListWebhooksAdminUseCase } from '../../../application/use-cases/webhooks/list-webhooks-admin.use-case';
import { GetWebhookDetailAdminUseCase } from '../../../application/use-cases/webhooks/get-webhook-detail-admin.use-case';
import { WebhooksController } from './webhooks.controller';

@Module({
  controllers: [WebhooksController],
  providers: [ListWebhooksAdminUseCase, GetWebhookDetailAdminUseCase],
})
export class WebhooksModule {}
