import { Module } from '@nestjs/common';
import { ListUsersAdminUseCase } from '../../../application/use-cases/users/list-users-admin.use-case';
import { SetUserAdminStateUseCase } from '../../../application/use-cases/users/set-user-admin-state.use-case';
import { UsersController } from './users.controller';

@Module({
  controllers: [UsersController],
  providers: [ListUsersAdminUseCase, SetUserAdminStateUseCase],
})
export class UsersModule {}
