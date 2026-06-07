import { Controller, Get, UseGuards } from '@nestjs/common';
import { GetSystemHealthUseCase } from '../../../application/use-cases/system/get-system-health.use-case';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';

@Controller('system')
@UseGuards(AdminJwtAuthGuard)
export class SystemController {
  constructor(private readonly getHealth: GetSystemHealthUseCase) {}

  @Get('health')
  health() {
    return this.getHealth.execute();
  }
}
