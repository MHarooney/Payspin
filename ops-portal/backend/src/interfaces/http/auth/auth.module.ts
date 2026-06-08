import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule, JwtSignOptions } from '@nestjs/jwt';
import { AdminLoginUseCase } from '../../../application/use-cases/auth/admin-login.use-case';
import { AuthController } from './auth.controller';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.getOrThrow<string>('ADMIN_JWT_SECRET');
        if (process.env.NODE_ENV === 'production' && secret.length < 32) {
          throw new Error(
            'ADMIN_JWT_SECRET is too weak for production (min 32 chars). ' +
              'Generate one with `openssl rand -hex 32`.',
          );
        }
        return {
          secret,
          signOptions: {
            algorithm: 'HS256',
            expiresIn: (config.get<string>('ADMIN_JWT_EXPIRES_IN') ??
              '15m') as JwtSignOptions['expiresIn'],
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AdminLoginUseCase],
  exports: [JwtModule],
})
export class AuthModule {}
