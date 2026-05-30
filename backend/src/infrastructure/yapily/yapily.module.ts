import { Module } from '@nestjs/common';
import { AIS_GATEWAY, PIS_GATEWAY } from '@payspin/pisp-provider';
import { YapilyHttpClient } from './yapily-http.client';
import { YapilyPisGateway } from './yapily-pis.gateway';
import { SandboxPisGateway } from './sandbox-pis.gateway';
import { YapilyAisGateway } from './yapily-ais.gateway';
import { SandboxAisGateway } from './sandbox-ais.gateway';

@Module({
  providers: [
    YapilyHttpClient,
    YapilyPisGateway,
    SandboxPisGateway,
    YapilyAisGateway,
    SandboxAisGateway,
    {
      provide: PIS_GATEWAY,
      useFactory: (http: YapilyHttpClient, yapily: YapilyPisGateway, sandbox: SandboxPisGateway) =>
        http.isConfigured ? yapily : sandbox,
      inject: [YapilyHttpClient, YapilyPisGateway, SandboxPisGateway],
    },
    {
      provide: AIS_GATEWAY,
      useFactory: (http: YapilyHttpClient, yapily: YapilyAisGateway, sandbox: SandboxAisGateway) =>
        http.isConfigured ? yapily : sandbox,
      inject: [YapilyHttpClient, YapilyAisGateway, SandboxAisGateway],
    },
  ],
  exports: [PIS_GATEWAY, AIS_GATEWAY, YapilyHttpClient],
})
export class YapilyModule {}
