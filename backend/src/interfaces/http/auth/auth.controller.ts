import { Body, Controller, Post } from '@nestjs/common';
import { LoginUserUseCase } from '../../../application/use-cases/auth/login-user.use-case';
import { RegisterUserUseCase } from '../../../application/use-cases/auth/register-user.use-case';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly registerUser: RegisterUserUseCase,
    private readonly loginUser: LoginUserUseCase,
  ) {}

  @Post('register')
  register(@Body() body: unknown) {
    return this.registerUser.execute(body);
  }

  @Post('login')
  login(@Body() body: unknown) {
    return this.loginUser.execute(body);
  }
}
