import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { GetTestingScenariosUseCase, RunTestingScenariosUseCase } from '../../../application/use-cases/testing/run-testing-scenarios.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';

@Controller('testing')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class TestingController {
  constructor(
    private readonly listScenarios: GetTestingScenariosUseCase,
    private readonly run: RunTestingScenariosUseCase,
  ) {}

  @Get('scenarios')
  scenarios() {
    return this.listScenarios.execute();
  }

  @Post('run')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  runScenarios(@Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    return this.run.execute(body, admin);
  }
}
