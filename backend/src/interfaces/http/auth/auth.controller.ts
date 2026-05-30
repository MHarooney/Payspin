import { Body, Controller, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { LoginUserUseCase } from '../../../application/use-cases/auth/login-user.use-case';
import { RegisterUserUseCase } from '../../../application/use-cases/auth/register-user.use-case';

// Tight per-IP limits on credential endpoints to slow brute-force / stuffing.
@Controller('auth')
@Throttle({ default: { limit: 10, ttl: 60000 } })
export class AuthController {
  constructor(
    private readonly registerUser: RegisterUserUseCase,
    private readonly loginUser: LoginUserUseCase,
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
}
