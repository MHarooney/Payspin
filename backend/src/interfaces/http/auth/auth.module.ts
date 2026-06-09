import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { LoginUserUseCase } from '../../../application/use-cases/auth/login-user.use-case';
import { PhoneSignInUseCase } from '../../../application/use-cases/auth/phone-sign-in.use-case';
import { RegisterUserUseCase } from '../../../application/use-cases/auth/register-user.use-case';
import { ReauthenticatePhoneUseCase } from '../../../application/use-cases/auth/reauthenticate-phone.use-case';
import { VerifyPhoneUseCase } from '../../../application/use-cases/auth/verify-phone.use-case';
import { AuthController } from './auth.controller';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.getOrThrow<string>('JWT_SECRET');
        // Fail fast on weak secrets in production: an HS256 key shorter than
        // 32 chars is brute-forceable and must never reach a live deployment.
        if (process.env.NODE_ENV === 'production' && secret.length < 32) {
          throw new Error(
            'JWT_SECRET is too weak for production (min 32 chars). ' +
              'Generate one with `openssl rand -hex 32`.',
          );
        }
        return {
          secret,
          signOptions: {
            algorithm: 'HS256',
            expiresIn: (config.get<string>('JWT_EXPIRES_IN') ?? '7d') as `${number}d`,
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [
    RegisterUserUseCase,
    LoginUserUseCase,
    VerifyPhoneUseCase,
    ReauthenticatePhoneUseCase,
    PhoneSignInUseCase,
  ],
  exports: [JwtModule],
})
export class AuthModule {}
