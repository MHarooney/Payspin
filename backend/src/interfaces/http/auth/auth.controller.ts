import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { LoginUserUseCase } from '../../../application/use-cases/auth/login-user.use-case';
import { RegisterUserUseCase } from '../../../application/use-cases/auth/register-user.use-case';
import { VerifyPhoneUseCase } from '../../../application/use-cases/auth/verify-phone.use-case';
import { CurrentUser } from '../decorators/current-user.decorator';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { AuthenticatedUser } from '../guards/jwt.strategy';

// Tight per-IP limits on credential endpoints to slow brute-force / stuffing.
@Controller('auth')
@Throttle({ default: { limit: 10, ttl: 60000 } })
export class AuthController {
  constructor(
    private readonly registerUser: RegisterUserUseCase,
    private readonly loginUser: LoginUserUseCase,
    private readonly verifyPhone: VerifyPhoneUseCase,
  ) {}

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  register(@Body() body: unknown) {
    return this.registerUser.execute(body);
  }

  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  login(@Body() body: unknown) {
    return this.loginUser.execute(body);
  }

  @Post('verify-phone')
  @UseGuards(JwtAuthGuard)
  verifyPhoneNumber(@CurrentUser() user: AuthenticatedUser, @Body() body: unknown) {
    return this.verifyPhone.execute(user.userId, body);
  }
}
