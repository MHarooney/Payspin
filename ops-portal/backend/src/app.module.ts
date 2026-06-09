import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { BullModule } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
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
    // Producer-only: ops enqueues FCM "push" jobs onto the shared notifications
    // queue; the main backend's worker consumes and delivers them.
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: { url: config.get<string>('REDIS_URL') ?? 'redis://localhost:6381' },
      }),
    }),
    OpsHttpModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
