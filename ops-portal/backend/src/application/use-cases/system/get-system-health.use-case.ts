import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ServiceHealth, SystemHealth } from '@payspin/shared-types';
import Redis from 'ioredis';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { OPS_REDIS } from '../../../infrastructure/redis/redis.module';

@Injectable()
export class GetSystemHealthUseCase {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(OPS_REDIS) private readonly redis: Redis,
    private readonly config: ConfigService,
  ) {}

  async execute(): Promise<SystemHealth> {
    const [db, redis, queue, yapily] = await Promise.all([
      this.checkDatabase(),
      this.checkRedis(),
      this.checkQueue(),
      this.checkYapily(),
    ]);

    const services: ServiceHealth[] = [
      { name: 'NestJS API', status: 'ok', stat: 'up', sub: 'ops-portal/backend' },
      db,
      redis,
      queue,
      yapily,
    ];

    const overall: SystemHealth['overall'] = services.some((s) => s.status === 'down')
      ? 'down'
      : services.some((s) => s.status === 'degraded')
        ? 'degraded'
        : 'ok';

    return { overall, services, checkedAt: new Date().toISOString() };
  }

  private async checkDatabase(): Promise<ServiceHealth> {
    const started = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      const users = await this.prisma.user.count();
      return {
        name: 'PostgreSQL',
        status: 'ok',
        stat: `${Date.now() - started}ms`,
        sub: `reachable · ${users} users`,
      };
    } catch {
      return { name: 'PostgreSQL', status: 'down', stat: 'down', sub: 'unreachable' };
    }
  }

  private async checkRedis(): Promise<ServiceHealth> {
    try {
      if (this.redis.status !== 'ready') {
        await this.redis.connect().catch(() => undefined);
      }
      const pong = await this.redis.ping();
      if (pong !== 'PONG') {
        return { name: 'Redis', status: 'down', stat: 'down', sub: 'no pong' };
      }
      const info = await this.redis.info('memory').catch(() => '');
      const match = /used_memory_human:(\S+)/.exec(info);
      return {
        name: 'Redis',
        status: 'ok',
        stat: match?.[1] ?? 'ok',
        sub: 'memory used',
      };
    } catch {
      return { name: 'Redis', status: 'down', stat: 'down', sub: 'unreachable' };
    }
  }

  private async checkQueue(): Promise<ServiceHealth> {
    try {
      if (this.redis.status !== 'ready') {
        await this.redis.connect().catch(() => undefined);
      }
      const keys = await this.redis.keys('bull:*:wait');
      let waiting = 0;
      for (const key of keys) {
        waiting += await this.redis.llen(key);
      }
      return {
        name: 'BullMQ Queue',
        status: waiting > 100 ? 'degraded' : 'ok',
        stat: `${waiting}`,
        sub: `jobs waiting · ${keys.length} queues`,
      };
    } catch {
      return { name: 'BullMQ Queue', status: 'degraded', stat: '?', sub: 'queue unreachable' };
    }
  }

  private async checkYapily(): Promise<ServiceHealth> {
    // Best-effort: the ops portal does not hold Yapily HTTP clients (those live in
    // the consumer backend via PIS_GATEWAY). We report configuration presence only.
    const configured = !!this.config.get<string>('YAPILY_APPLICATION_ID');
    return {
      name: 'Yapily API',
      status: configured ? 'ok' : 'degraded',
      stat: configured ? 'configured' : 'unset',
      sub: configured ? 'credentials present' : 'no sandbox creds',
    };
  }
}
