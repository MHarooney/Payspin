import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { GetFeatureFlagsUseCase } from '../../../application/use-cases/config/get-feature-flags.use-case';
import { GetPlatformConfigUseCase } from '../../../application/use-cases/config/get-platform-config.use-case';
import { UpdateFeatureFlagUseCase } from '../../../application/use-cases/config/update-feature-flag.use-case';
import { UpdatePlatformConfigUseCase } from '../../../application/use-cases/config/update-platform-config.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';

@Controller('config')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class ConfigController {
  constructor(
    private readonly getFlags: GetFeatureFlagsUseCase,
    private readonly updateFlag: UpdateFeatureFlagUseCase,
    private readonly getPlatform: GetPlatformConfigUseCase,
    private readonly updatePlatform: UpdatePlatformConfigUseCase,
  ) {}

  @Get('flags')
  flags() {
    return this.getFlags.execute();
  }

  @Patch('flags/:key')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  setFlag(
    @Param('key') key: string,
    @Body() body: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    return this.updateFlag.execute(key, body, admin);
  }

  @Get('platform')
  platform() {
    return this.getPlatform.execute();
  }

  @Patch('platform/:key')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  setPlatform(
    @Param('key') key: string,
    @Body() body: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    return this.updatePlatform.execute(key, body, admin);
  }
}
