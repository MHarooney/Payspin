import { Module } from '@nestjs/common';
import { AIS_GATEWAY, PIS_GATEWAY } from '@payspin/pisp-provider';
import { YapilyHttpClient } from './yapily-http.client';
import { YapilyPisGateway } from './yapily-pis.gateway';
import { SandboxPisGateway } from './sandbox-pis.gateway';
import { YapilyAisGateway } from './yapily-ais.gateway';
import { SandboxAisGateway } from './sandbox-ais.gateway';

/**
 * In production the forgeable sandbox gateway must never be selected: it
 * accepts any webhook signature and auto-completes payments. Refuse to boot
 * unless real Yapily credentials are configured.
 */
function assertNotSandboxInProduction(http: YapilyHttpClient): void {
  const allowSandbox = process.env.PAYSPIN_ALLOW_SANDBOX_GATEWAY === 'true';
  if (process.env.NODE_ENV === 'production' && !http.isConfigured && !allowSandbox) {
    throw new Error(
      'Refusing to start in production with the Yapily sandbox gateway. ' +
        'Set YAPILY_APP_KEY and YAPILY_APP_SECRET.',
    );
  }
}

@Module({
  providers: [
    YapilyHttpClient,
    YapilyPisGateway,
    SandboxPisGateway,
    YapilyAisGateway,
    SandboxAisGateway,
    {
      provide: PIS_GATEWAY,
      useFactory: (http: YapilyHttpClient, yapily: YapilyPisGateway, sandbox: SandboxPisGateway) => {
        assertNotSandboxInProduction(http);
        return http.isConfigured ? yapily : sandbox;
      },
      inject: [YapilyHttpClient, YapilyPisGateway, SandboxPisGateway],
    },
    {
      provide: AIS_GATEWAY,
      useFactory: (http: YapilyHttpClient, yapily: YapilyAisGateway, sandbox: SandboxAisGateway) => {
        assertNotSandboxInProduction(http);
        return http.isConfigured ? yapily : sandbox;
      },
      inject: [YapilyHttpClient, YapilyAisGateway, SandboxAisGateway],
    },
  ],
  exports: [PIS_GATEWAY, AIS_GATEWAY, YapilyHttpClient],
})
export class YapilyModule {}
