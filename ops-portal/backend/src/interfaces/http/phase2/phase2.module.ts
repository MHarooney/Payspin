import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { GetAppControlsUseCase } from '../../../application/use-cases/app-controls/get-app-controls.use-case';
import { ListComplianceAlertsUseCase } from '../../../application/use-cases/compliance/list-compliance-alerts.use-case';
import { ListDisputesUseCase } from '../../../application/use-cases/disputes/list-disputes.use-case';
import { ListReconciliationExceptionsUseCase } from '../../../application/use-cases/finance/list-reconciliation-exceptions.use-case';
import { GetSupportThreadUseCase } from '../../../application/use-cases/messages/get-support-thread.use-case';
import { ListSupportThreadsUseCase } from '../../../application/use-cases/messages/list-support-threads.use-case';
import { MarkSupportThreadReadUseCase } from '../../../application/use-cases/messages/mark-support-thread-read.use-case';
import { PatchSupportThreadUseCase } from '../../../application/use-cases/messages/patch-support-thread.use-case';
import { ReplyToSupportThreadUseCase } from '../../../application/use-cases/messages/reply-to-support-thread.use-case';
import { NotifySupportReplyUseCase } from '../../../application/use-cases/notifications/notify-support-reply.use-case';
import { GetReportSeriesUseCase } from '../../../application/use-cases/reports/get-report-series.use-case';
import { NOTIFICATIONS_QUEUE } from '../../../infrastructure/queue/notification.queue';
import { Phase2Controller } from './phase2.controller';

@Module({
  imports: [BullModule.registerQueue({ name: NOTIFICATIONS_QUEUE })],
  controllers: [Phase2Controller],
  providers: [
    ListComplianceAlertsUseCase,
    ListDisputesUseCase,
    ListReconciliationExceptionsUseCase,
    ListSupportThreadsUseCase,
    GetSupportThreadUseCase,
    ReplyToSupportThreadUseCase,
    PatchSupportThreadUseCase,
    MarkSupportThreadReadUseCase,
    NotifySupportReplyUseCase,
    GetReportSeriesUseCase,
    GetAppControlsUseCase,
    // PrismaService and AuditService are @Global() — no need to import
  ],
})
export class Phase2Module {}
