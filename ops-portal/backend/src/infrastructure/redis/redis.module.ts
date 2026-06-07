import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export const OPS_REDIS = Symbol('OPS_REDIS');

@Global()
@Module({
  providers: [
    {
      provide: OPS_REDIS,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        new Redis(config.get<string>('REDIS_URL') ?? 'redis://localhost:6381', {
          maxRetriesPerRequest: 1,
          enableOfflineQueue: false,
          lazyConnect: true,
        }),
    },
  ],
  exports: [OPS_REDIS],
})
export class RedisModule {}
