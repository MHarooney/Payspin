import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { CreateNotificationUseCase } from '../../../application/use-cases/notifications/create-notification.use-case';
import { ListNotificationsUseCase } from '../../../application/use-cases/notifications/list-notifications.use-case';
import { MarkNotificationReadUseCase } from '../../../application/use-cases/notifications/mark-notification-read.use-case';
import { NotifyPaymentReceivedUseCase } from '../../../application/use-cases/notifications/notify-payment-received.use-case';
import { RegisterDeviceTokenUseCase } from '../../../application/use-cases/notifications/register-device-token.use-case';
import { SendPushNotificationUseCase } from '../../../application/use-cases/notifications/send-push-notification.use-case';
import { NOTIFICATIONS_QUEUE, NotificationProcessor } from '../../../infrastructure/queue/notification.processor';
import { NotificationsController } from './notifications.controller';

@Module({
  imports: [BullModule.registerQueue({ name: NOTIFICATIONS_QUEUE })],
  controllers: [NotificationsController],
  providers: [
    ListNotificationsUseCase,
    MarkNotificationReadUseCase,
    RegisterDeviceTokenUseCase,
    CreateNotificationUseCase,
    SendPushNotificationUseCase,
    NotifyPaymentReceivedUseCase,
    NotificationProcessor,
  ],
  exports: [NotifyPaymentReceivedUseCase],
})
export class NotificationsModule {}
