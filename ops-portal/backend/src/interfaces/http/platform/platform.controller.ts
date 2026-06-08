import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { ListAuditEventsUseCase } from '../../../application/use-cases/audit/list-audit-events.use-case';
import { ActivateKillSwitchUseCase } from '../../../application/use-cases/kill-switch/activate-kill-switch.use-case';
import { GetKillSwitchStateUseCase } from '../../../application/use-cases/kill-switch/get-kill-switch-state.use-case';
import { GlobalSearchUseCase } from '../../../application/use-cases/search/global-search.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';

@Controller()
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class PlatformController {
  constructor(
    private readonly getKillSwitch: GetKillSwitchStateUseCase,
    private readonly activateKillSwitch: ActivateKillSwitchUseCase,
    private readonly listAudit: ListAuditEventsUseCase,
    private readonly search: GlobalSearchUseCase,
  ) {}

  @Get('kill-switch')
  killSwitchState() {
    return this.getKillSwitch.execute();
  }

  @Post('kill-switch')
  @Roles(AdminRole.SUPER_ADMIN)
  setKillSwitch(@Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    return this.activateKillSwitch.execute(body, admin);
  }

  @Get('audit')
  audit(@Query() query: unknown) {
    return this.listAudit.execute(query);
  }

  @Get('search')
  globalSearch(@Query() query: unknown) {
    return this.search.execute(query);
  }
}
