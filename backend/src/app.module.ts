import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { BullModule } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppConfigModule } from './infrastructure/persistence/prisma.module';
import { EncryptionModule } from './infrastructure/encryption/encryption.module';
import { FirebaseModule } from './infrastructure/firebase/firebase.module';
import { HttpApiModule } from './interfaces/http/http-api.module';
import { WebhooksModule } from './interfaces/webhooks/webhooks.module';

@Module({
  imports: [
    AppConfigModule,
    EncryptionModule,
    FirebaseModule,
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: { url: config.get<string>('REDIS_URL') ?? 'redis://localhost:6379' },
      }),
    }),
    HttpApiModule,
    WebhooksModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
