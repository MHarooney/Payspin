import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AdminRole } from '@payspin/shared-types';
import { CreateUserAdminUseCase } from '../../../application/use-cases/users/create-user-admin.use-case';
import { DeleteUserAdminUseCase } from '../../../application/use-cases/users/delete-user-admin.use-case';
import { GetUserDetailAdminUseCase } from '../../../application/use-cases/users/get-user-detail-admin.use-case';
import { ListUsersAdminUseCase } from '../../../application/use-cases/users/list-users-admin.use-case';
import { PatchUserAdminUseCase } from '../../../application/use-cases/users/patch-user-admin.use-case';
import { ResetPasswordAdminUseCase } from '../../../application/use-cases/users/reset-password-admin.use-case';
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
    private readonly createUser: CreateUserAdminUseCase,
    private readonly patchUser: PatchUserAdminUseCase,
    private readonly deleteUser: DeleteUserAdminUseCase,
    private readonly resetPassword: ResetPasswordAdminUseCase,
    private readonly setState: SetUserAdminStateUseCase,
  ) {}

  @Get()
  list(@Query() query: unknown) {
    return this.listUsers.execute(query);
  }

  @Post()
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  create(@Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    return this.createUser.execute(body, admin);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.getDetail.execute(id);
  }

  @Patch(':id')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS, AdminRole.SUPPORT)
  patch(@Param('id') id: string, @Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    return this.patchUser.execute(id, body, admin);
  }

  @Delete(':id')
  @Roles(AdminRole.SUPER_ADMIN)
  remove(@Param('id') id: string, @CurrentAdmin() admin: AdminRequestContext) {
    return this.deleteUser.execute(id, admin);
  }

  @Post(':id/reset-password')
  @Roles(AdminRole.SUPER_ADMIN, AdminRole.OPS)
  resetPwd(@Param('id') id: string, @Body() body: unknown, @CurrentAdmin() admin: AdminRequestContext) {
    return this.resetPassword.execute(id, body, admin);
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
