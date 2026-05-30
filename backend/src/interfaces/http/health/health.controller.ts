import {
  Controller,
  Get,
  Inject,
  ServiceUnavailableException,
} from '@nestjs/common';
import Redis from 'ioredis';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { HEALTH_REDIS } from './health.tokens';

@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(HEALTH_REDIS) private readonly redis: Redis,
  ) {}

  /** Liveness — process is up. */
  @Get()
  check() {
    return { status: 'ok', service: 'payspin-api' };
  }

  /** Readiness — dependencies (Postgres + Redis) are reachable. */
  @Get('ready')
  async ready() {
    const [database, redis] = await Promise.all([
      this.pingDatabase(),
      this.pingRedis(),
    ]);

    if (!database || !redis) {
      throw new ServiceUnavailableException({
        status: 'degraded',
        checks: {
          database: database ? 'ok' : 'down',
          redis: redis ? 'ok' : 'down',
        },
      });
    }

    return { status: 'ok', checks: { database: 'ok', redis: 'ok' } };
  }

  private async pingDatabase(): Promise<boolean> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return true;
    } catch {
      return false;
    }
  }

  private async pingRedis(): Promise<boolean> {
    try {
      if (this.redis.status !== 'ready') {
        await this.redis.connect().catch(() => undefined);
      }
      return (await this.redis.ping()) === 'PONG';
    } catch {
      return false;
    }
  }
}
