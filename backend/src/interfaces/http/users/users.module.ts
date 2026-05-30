import { Module } from '@nestjs/common';
import { GetUserProfileUseCase } from '../../../application/use-cases/users/get-user-profile.use-case';
import { UpdateUserProfileUseCase } from '../../../application/use-cases/users/update-user-profile.use-case';
import { UsersController } from './users.controller';

@Module({
  controllers: [UsersController],
  providers: [GetUserProfileUseCase, UpdateUserProfileUseCase],
})
export class UsersModule {}
