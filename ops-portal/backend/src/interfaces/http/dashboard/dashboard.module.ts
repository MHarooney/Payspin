import { Module } from '@nestjs/common';
import { GetDashboardKpisUseCase } from '../../../application/use-cases/dashboard/get-dashboard-kpis.use-case';
import { GetVolumeSeriesUseCase } from '../../../application/use-cases/dashboard/get-volume-series.use-case';
import { ListOpenAlertsUseCase } from '../../../application/use-cases/dashboard/list-open-alerts.use-case';
import { DashboardController } from './dashboard.controller';

@Module({
  controllers: [DashboardController],
  providers: [GetDashboardKpisUseCase, GetVolumeSeriesUseCase, ListOpenAlertsUseCase],
})
export class DashboardModule {}
