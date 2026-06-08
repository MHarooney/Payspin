import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import {
  patchComplianceAlertSchema,
  patchDisputeAdminSchema,
  createSupportMessageSchema,
  patchSupportThreadSchema,
} from '@payspin/validators';
import { GetAppControlsUseCase } from '../../../application/use-cases/app-controls/get-app-controls.use-case';
import { ListComplianceAlertsUseCase } from '../../../application/use-cases/compliance/list-compliance-alerts.use-case';
import { ListDisputesUseCase } from '../../../application/use-cases/disputes/list-disputes.use-case';
import { ListReconciliationExceptionsUseCase } from '../../../application/use-cases/finance/list-reconciliation-exceptions.use-case';
import { GetSupportThreadUseCase } from '../../../application/use-cases/messages/get-support-thread.use-case';
import { ListSupportThreadsUseCase } from '../../../application/use-cases/messages/list-support-threads.use-case';
import { GetReportSeriesUseCase } from '../../../application/use-cases/reports/get-report-series.use-case';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { AuditService } from '../../../infrastructure/audit/audit.service';
import { AuditAction } from '../../../domain/constants';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';

@Controller()
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class Phase2Controller {
  constructor(
    private readonly listCompliance: ListComplianceAlertsUseCase,
    private readonly listDisputes: ListDisputesUseCase,
    private readonly listExceptions: ListReconciliationExceptionsUseCase,
    private readonly listThreads: ListSupportThreadsUseCase,
    private readonly getThread: GetSupportThreadUseCase,
    private readonly getReports: GetReportSeriesUseCase,
    private readonly getAppControls: GetAppControlsUseCase,
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  @Get('compliance')
  compliance() {
    return this.listCompliance.execute();
  }

  @Patch('compliance/:id')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS, AdminRole.SUPPORT)
  async patchCompliance(
    @Param('id') id: string,
    @Body() body: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    const input = patchComplianceAlertSchema.parse(body);
    const before = await this.prisma.complianceAlert.findUnique({ where: { id } });
    const updated = await this.prisma.complianceAlert.update({
      where: { id },
      data: { status: input.status },
    });
    await this.audit.record(
      { adminUserId: admin.adminUserId, adminEmail: admin.email, ip: admin.ip, userAgent: admin.userAgent },
      { action: AuditAction.COMPLIANCE_UPDATE, targetType: 'compliance_alert', targetId: id, before: { status: before?.status }, after: { status: input.status, note: input.note } },
    );
    return updated;
  }

  @Get('disputes')
  disputes() {
    return this.listDisputes.execute();
  }

  @Patch('disputes/:id')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS, AdminRole.SUPPORT)
  async patchDispute(
    @Param('id') id: string,
    @Body() body: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    const input = patchDisputeAdminSchema.parse(body);
    const before = await this.prisma.dispute.findUnique({ where: { id } });
    const updated = await this.prisma.dispute.update({
      where: { id },
      data: { status: input.status, ...(input.note ? { note: input.note } : {}) },
    });
    await this.audit.record(
      { adminUserId: admin.adminUserId, adminEmail: admin.email, ip: admin.ip, userAgent: admin.userAgent },
      { action: AuditAction.DISPUTE_UPDATE, targetType: 'dispute', targetId: id, before: { status: before?.status }, after: { status: input.status } },
    );
    return updated;
  }

  @Get('finance/exceptions')
  finance() {
    return this.listExceptions.execute();
  }

  @Get('messages')
  messages() {
    return this.listThreads.execute();
  }

  @Get('messages/:id')
  message(@Param('id') id: string) {
    return this.getThread.execute(id);
  }

  @Post('messages/threads/:id/reply')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS, AdminRole.SUPPORT)
  async replyToThread(
    @Param('id') id: string,
    @Body() body: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    const input = createSupportMessageSchema.parse(body);
    const thread = await this.prisma.supportThread.findUnique({ where: { id } });
    if (!thread) throw new Error('Thread not found');
    const message = await this.prisma.supportMessage.create({
      data: {
        threadId: id,
        direction: 'OUT',
        body: input.body,
        authorName: admin.email,
      },
    });
    await this.prisma.supportThread.update({
      where: { id },
      data: { lastMessageAt: new Date(), unread: false },
    });
    await this.audit.record(
      { adminUserId: admin.adminUserId, adminEmail: admin.email, ip: admin.ip, userAgent: admin.userAgent },
      { action: AuditAction.SUPPORT_REPLY, targetType: 'support_thread', targetId: id },
    );
    return message;
  }

  @Patch('messages/threads/:id')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS, AdminRole.SUPPORT)
  async patchThread(
    @Param('id') id: string,
    @Body() body: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    const input = patchSupportThreadSchema.parse(body);
    const updated = await this.prisma.supportThread.update({
      where: { id },
      data: { status: input.status },
    });
    await this.audit.record(
      { adminUserId: admin.adminUserId, adminEmail: admin.email, ip: admin.ip, userAgent: admin.userAgent },
      { action: AuditAction.SUPPORT_THREAD_UPDATE, targetType: 'support_thread', targetId: id, after: { status: input.status } },
    );
    return updated;
  }

  @Get('reports')
  reports(@Query() query: unknown) {
    return this.getReports.execute(query);
  }

  @Get('app-controls')
  appControls() {
    return this.getAppControls.execute();
  }
}


