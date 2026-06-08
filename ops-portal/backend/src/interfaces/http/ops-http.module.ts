import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AdminUsersModule } from './admin-users/admin-users.module';
import { AuthModule } from './auth/auth.module';
import { CirclesModule } from './circles/circles.module';
import { ConfigFeatureModule } from './config/config.module';
import { DataModule } from './data/data.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { PaymentLinksModule } from './payment-links/payment-links.module';
import { Phase2Module } from './phase2/phase2.module';
import { PlatformModule } from './platform/platform.module';
import { SystemModule } from './system/system.module';
import { TransactionsModule } from './transactions/transactions.module';
import { UsersModule } from './users/users.module';
import { WebhooksModule } from './webhooks/webhooks.module';
import { AdminJwtStrategy } from './guards/admin-jwt.strategy';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'admin-jwt' }),
    AuthModule,
    DashboardModule,
    TransactionsModule,
    UsersModule,
    CirclesModule,
    SystemModule,
    ConfigFeatureModule,
    PlatformModule,
    Phase2Module,
    DataModule,
    WebhooksModule,
    PaymentLinksModule,
    AdminUsersModule,
  ],
  providers: [AdminJwtStrategy],
})
export class OpsHttpModule {}
