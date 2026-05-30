import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { BankAccountsModule } from './bank-accounts/bank-accounts.module';
import { PaymentLinksModule } from './payment-links/payment-links.module';
import { PaymentsModule } from './payments/payments.module';
import { OpenBankingModule } from './open-banking/open-banking.module';
import { CirclesModule } from './circles/circles.module';
import { HealthModule } from './health/health.module';
import { JwtStrategy } from './guards/jwt.strategy';
import { YapilyModule } from '../../infrastructure/yapily/yapily.module';

@Module({
  imports: [
    YapilyModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    AuthModule,
    UsersModule,
    BankAccountsModule,
    PaymentLinksModule,
    PaymentsModule,
    OpenBankingModule,
    CirclesModule,
    HealthModule,
  ],
  providers: [JwtStrategy],
})
export class HttpApiModule {}
