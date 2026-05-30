import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { GetUserProfileUseCase } from '../../../application/use-cases/users/get-user-profile.use-case';
import { UpdateUserProfileUseCase } from '../../../application/use-cases/users/update-user-profile.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly getProfile: GetUserProfileUseCase,
    private readonly updateProfile: UpdateUserProfileUseCase,
  ) {}

  @Get('me')
  getMe(@CurrentUser() user: AuthenticatedUser) {
    return this.getProfile.execute(user.userId);
  }

  @Patch('me')
  patchMe(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.updateProfile.execute(user.userId, body);
  }
}
