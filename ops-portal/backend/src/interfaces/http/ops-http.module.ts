import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AuthModule } from './auth/auth.module';
import { CirclesModule } from './circles/circles.module';
import { ConfigFeatureModule } from './config/config.module';
import { DataModule } from './data/data.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { Phase2Module } from './phase2/phase2.module';
import { PlatformModule } from './platform/platform.module';
import { SystemModule } from './system/system.module';
import { TransactionsModule } from './transactions/transactions.module';
import { UsersModule } from './users/users.module';
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
  ],
  providers: [AdminJwtStrategy],
})
export class OpsHttpModule {}
