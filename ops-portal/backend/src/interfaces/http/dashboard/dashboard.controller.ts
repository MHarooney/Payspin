import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { GetDashboardKpisUseCase } from '../../../application/use-cases/dashboard/get-dashboard-kpis.use-case';
import { GetVolumeSeriesUseCase } from '../../../application/use-cases/dashboard/get-volume-series.use-case';
import { ListOpenAlertsUseCase } from '../../../application/use-cases/dashboard/list-open-alerts.use-case';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';

@Controller('dashboard')
@UseGuards(AdminJwtAuthGuard)
export class DashboardController {
  constructor(
    private readonly getKpis: GetDashboardKpisUseCase,
    private readonly getVolume: GetVolumeSeriesUseCase,
    private readonly listAlerts: ListOpenAlertsUseCase,
  ) {}

  @Get('kpis')
  kpis(@Query() query: unknown) {
    return this.getKpis.execute(query);
  }

  @Get('volume')
  volume(@Query() query: unknown) {
    return this.getVolume.execute(query);
  }

  @Get('alerts')
  alerts() {
    return this.listAlerts.execute();
  }
}
