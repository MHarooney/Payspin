import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { YapilyModule } from '../../infrastructure/yapily/yapily.module';
import { YAPILY_WEBHOOK_QUEUE, YapilyWebhookProcessor } from '../../infrastructure/queue/yapily-webhook.processor';
import { NotificationsModule } from '../http/notifications/notifications.module';
import { YapilyWebhooksController } from './yapily-webhooks.controller';

@Module({
  imports: [
    YapilyModule,
    NotificationsModule,
    BullModule.registerQueue({ name: YAPILY_WEBHOOK_QUEUE }),
  ],
  controllers: [YapilyWebhooksController],
  providers: [YapilyWebhookProcessor],
})
export class WebhooksModule {}
