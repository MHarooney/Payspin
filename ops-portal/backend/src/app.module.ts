import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppConfigModule } from './infrastructure/persistence/prisma.module';
import { RedisModule } from './infrastructure/redis/redis.module';
import { AuditModule } from './infrastructure/audit/audit.module';
import { OpsHttpModule } from './interfaces/http/ops-http.module';

@Module({
  imports: [
    AppConfigModule,
    RedisModule,
    AuditModule,
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 200 }]),
    OpsHttpModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
