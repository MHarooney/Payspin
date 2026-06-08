import { Module } from '@nestjs/common';
import { GetUserDetailAdminUseCase } from '../../../application/use-cases/users/get-user-detail-admin.use-case';
import { ListUsersAdminUseCase } from '../../../application/use-cases/users/list-users-admin.use-case';
import { SetUserAdminStateUseCase } from '../../../application/use-cases/users/set-user-admin-state.use-case';
import { UsersController } from './users.controller';

@Module({
  controllers: [UsersController],
  providers: [ListUsersAdminUseCase, GetUserDetailAdminUseCase, SetUserAdminStateUseCase],
})
export class UsersModule {}
