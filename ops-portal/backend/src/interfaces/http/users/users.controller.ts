import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { GetUserDetailAdminUseCase } from '../../../application/use-cases/users/get-user-detail-admin.use-case';
import { ListUsersAdminUseCase } from '../../../application/use-cases/users/list-users-admin.use-case';
import { SetUserAdminStateUseCase } from '../../../application/use-cases/users/set-user-admin-state.use-case';
import { CurrentAdmin, AdminRequestContext } from '../decorators/current-admin.decorator';
import { AdminJwtAuthGuard } from '../guards/admin-jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../guards/roles.decorator';

@Controller('users')
@UseGuards(AdminJwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(
    private readonly listUsers: ListUsersAdminUseCase,
    private readonly getDetail: GetUserDetailAdminUseCase,
    private readonly setState: SetUserAdminStateUseCase,
  ) {}

  @Get()
  list(@Query() query: unknown) {
    return this.listUsers.execute(query);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.getDetail.execute(id);
  }

  @Post(':id/state')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  state(
    @Param('id') id: string,
    @Body() body: unknown,
    @CurrentAdmin() admin: AdminRequestContext,
  ) {
    return this.setState.execute(id, body, admin);
  }
}
