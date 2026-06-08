import { Module } from '@nestjs/common';
import { CreateUserAdminUseCase } from '../../../application/use-cases/users/create-user-admin.use-case';
import { DeleteUserAdminUseCase } from '../../../application/use-cases/users/delete-user-admin.use-case';
import { GetUserDetailAdminUseCase } from '../../../application/use-cases/users/get-user-detail-admin.use-case';
import { GetUsersSummaryAdminUseCase } from '../../../application/use-cases/users/get-users-summary-admin.use-case';
import { ListUsersAdminUseCase } from '../../../application/use-cases/users/list-users-admin.use-case';
import { PatchUserAdminUseCase } from '../../../application/use-cases/users/patch-user-admin.use-case';
import { ResetPasswordAdminUseCase } from '../../../application/use-cases/users/reset-password-admin.use-case';
import { SetUserAdminStateUseCase } from '../../../application/use-cases/users/set-user-admin-state.use-case';
import { UserTestSetupAdminUseCase } from '../../../application/use-cases/users/user-test-setup-admin.use-case';
import { PaymentLinksModule } from '../payment-links/payment-links.module';
import { UsersController } from './users.controller';

@Module({
  imports: [PaymentLinksModule],
  controllers: [UsersController],
  providers: [
    ListUsersAdminUseCase,
    GetUserDetailAdminUseCase,
    GetUsersSummaryAdminUseCase,
    CreateUserAdminUseCase,
    PatchUserAdminUseCase,
    DeleteUserAdminUseCase,
    ResetPasswordAdminUseCase,
    SetUserAdminStateUseCase,
    UserTestSetupAdminUseCase,
  ],
  exports: [
    CreateUserAdminUseCase,
    PatchUserAdminUseCase,
    DeleteUserAdminUseCase,
    SetUserAdminStateUseCase,
  ],
})
export class UsersModule {}
