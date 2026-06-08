import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { GetAppControlsUseCase } from '../../../application/use-cases/app-controls/get-app-controls.use-case';
import { ListComplianceAlertsUseCase } from '../../../application/use-cases/compliance/list-compliance-alerts.use-case';
import { ListDisputesUseCase } from '../../../application/use-cases/disputes/list-disputes.use-case';
import { ListReconciliationExceptionsUseCase } from '../../../application/use-cases/finance/list-reconciliation-exceptions.use-case';
import { GetSupportThreadUseCase } from '../../../application/use-cases/messages/get-support-thread.use-case';
import { ListSupportThreadsUseCase } from '../../../application/use-cases/messages/list-support-threads.use-case';
import { GetReportSeriesUseCase } from '../../../application/use-cases/reports/get-report-series.use-case';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';

@Controller()
@UseGuards(AdminJwtAuthGuard)
export class Phase2Controller {
  constructor(
    private readonly listCompliance: ListComplianceAlertsUseCase,
    private readonly listDisputes: ListDisputesUseCase,
    private readonly listExceptions: ListReconciliationExceptionsUseCase,
    private readonly listThreads: ListSupportThreadsUseCase,
    private readonly getThread: GetSupportThreadUseCase,
    private readonly getReports: GetReportSeriesUseCase,
    private readonly getAppControls: GetAppControlsUseCase,
  ) {}

  @Get('compliance')
  compliance() {
    return this.listCompliance.execute();
  }

  @Get('disputes')
  disputes() {
    return this.listDisputes.execute();
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

  @Get('reports')
  reports(@Query() query: unknown) {
    return this.getReports.execute(query);
  }

  @Get('app-controls')
  appControls() {
    return this.getAppControls.execute();
  }
}
