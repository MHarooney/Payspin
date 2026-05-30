import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { HealthController } from './health.controller';
import { HEALTH_REDIS } from './health.tokens';

@Module({
  controllers: [HealthController],
  providers: [
    {
      provide: HEALTH_REDIS,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        new Redis(config.get<string>('REDIS_URL') ?? 'redis://localhost:6379', {
          maxRetriesPerRequest: 1,
          enableOfflineQueue: false,
          lazyConnect: true,
        }),
    },
  ],
})
export class HealthModule {}
