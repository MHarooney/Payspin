import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TestRunResult, TestScenarioInfo, TestStepResult } from '@payspin/shared-types';
import { runTestingScenariosSchema } from '@payspin/validators';
import Redis from 'ioredis';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../../infrastructure/persistence/prisma.module';
import { OPS_REDIS } from '../../../infrastructure/redis/redis.module';
import { GetSystemHealthUseCase } from '../system/get-system-health.use-case';
import { CreatePaymentLinkAdminUseCase } from '../payment-links/create-payment-link-admin.use-case';
import { CreateUserAdminUseCase } from '../users/create-user-admin.use-case';
import { DeleteUserAdminUseCase } from '../users/delete-user-admin.use-case';
import { PatchUserAdminUseCase } from '../users/patch-user-admin.use-case';
import { AdminRequestContext } from '../../../interfaces/http/decorators/current-admin.decorator';

const SCENARIOS: TestScenarioInfo[] = [
  {
    id: 'ops_health',
    label: 'Ops health',
    description: 'Database, Redis, and ops system health checks',
    mutating: false,
  },
  {
    id: 'consumer_api',
    label: 'Consumer API',
    description: 'Reachability of the main Payspin API',
    mutating: false,
  },
  {
    id: 'user_crud',
    label: 'User CRUD',
    description: 'Create, patch, and soft-delete an ephemeral test user',
    mutating: true,
  },
  {
    id: 'payment_link',
    label: 'Payment link',
    description: 'Create a test payment link for a user with a bank account',
    mutating: true,
  },
  {
    id: 'webhooks',
    label: 'Webhooks',
    description: 'List webhooks endpoint shape sanity',
    mutating: false,
  },
];

@Injectable()
export class GetTestingScenariosUseCase {
  execute(): TestScenarioInfo[] {
    return SCENARIOS;
  }
}

@Injectable()
export class RunTestingScenariosUseCase {
  private readonly lastRun = new Map<string, number>();

  constructor(
    private readonly prisma: PrismaService,
    @Inject(OPS_REDIS) private readonly redis: Redis,
    private readonly config: ConfigService,
    private readonly systemHealth: GetSystemHealthUseCase,
    private readonly createUser: CreateUserAdminUseCase,
    private readonly patchUser: PatchUserAdminUseCase,
    private readonly deleteUser: DeleteUserAdminUseCase,
    private readonly createLink: CreatePaymentLinkAdminUseCase,
  ) {}

  async execute(body: unknown, ctx: AdminRequestContext): Promise<TestRunResult> {
    const { scenarios } = runTestingScenariosSchema.parse(body);
    const rateKey = `ops:test-run:${ctx.adminUserId}`;
    const now = Date.now();
    const last = this.lastRun.get(rateKey) ?? 0;
    if (now - last < 60_000) {
      throw new HttpException('Wait at least 60 seconds between test runs', HttpStatus.TOO_MANY_REQUESTS);
    }
    this.lastRun.set(rateKey, now);

    const startedAt = new Date().toISOString();
    const steps: TestStepResult[] = [];

    for (const id of scenarios) {
      switch (id) {
        case 'ops_health':
          steps.push(...(await this.runOpsHealth()));
          break;
        case 'consumer_api':
          steps.push(await this.runConsumerApi());
          break;
        case 'user_crud':
          steps.push(...(await this.runUserCrud(ctx)));
          break;
        case 'payment_link':
          steps.push(await this.runPaymentLink(ctx));
          break;
        case 'webhooks':
          steps.push(await this.runWebhooks());
          break;
      }
    }

    return { runId: randomUUID(), startedAt, steps };
  }

  private async runOpsHealth(): Promise<TestStepResult[]> {
    const steps: TestStepResult[] = [];
    const t0 = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      steps.push({ id: 'db', label: 'PostgreSQL ping', status: 'pass', durationMs: Date.now() - t0 });
    } catch (e) {
      steps.push({ id: 'db', label: 'PostgreSQL ping', status: 'fail', detail: String(e), durationMs: Date.now() - t0 });
    }

    const t1 = Date.now();
    try {
      await this.redis.ping();
      steps.push({ id: 'redis', label: 'Redis ping', status: 'pass', durationMs: Date.now() - t1 });
    } catch (e) {
      steps.push({ id: 'redis', label: 'Redis ping', status: 'fail', detail: String(e), durationMs: Date.now() - t1 });
    }

    const t2 = Date.now();
    try {
      const health = await this.systemHealth.execute();
      steps.push({
        id: 'system',
        label: 'System health aggregate',
        status: health.overall === 'down' ? 'fail' : health.overall === 'degraded' ? 'warn' : 'pass',
        detail: `overall=${health.overall}`,
        durationMs: Date.now() - t2,
      });
    } catch (e) {
      steps.push({ id: 'system', label: 'System health aggregate', status: 'fail', detail: String(e), durationMs: Date.now() - t2 });
    }

    return steps;
  }

  private async runConsumerApi(): Promise<TestStepResult> {
    const base = (this.config.get<string>('CONSUMER_API_URL') ?? 'http://localhost:3001/v1').replace(/\/$/, '');
    const t0 = Date.now();
    try {
      const res = await fetch(`${base}/health`, { signal: AbortSignal.timeout(5000) });
      return {
        id: 'consumer_api',
        label: 'Consumer API /health',
        status: res.ok ? 'pass' : 'fail',
        detail: `HTTP ${res.status}`,
        durationMs: Date.now() - t0,
      };
    } catch (e) {
      return {
        id: 'consumer_api',
        label: 'Consumer API /health',
        status: 'fail',
        detail: String(e),
        durationMs: Date.now() - t0,
      };
    }
  }

  private async runUserCrud(ctx: AdminRequestContext): Promise<TestStepResult[]> {
    const email = `ops-test-${Date.now()}@payspin.test`;
    const steps: TestStepResult[] = [];
    let userId = '';

    const t0 = Date.now();
    try {
      const created = await this.createUser.execute({ email, displayName: 'Ops Test User' }, ctx);
      userId = created.id;
      steps.push({ id: 'user_create', label: 'Create test user', status: 'pass', detail: email, durationMs: Date.now() - t0 });
    } catch (e) {
      steps.push({ id: 'user_create', label: 'Create test user', status: 'fail', detail: String(e), durationMs: Date.now() - t0 });
      return steps;
    }

    const t1 = Date.now();
    try {
      await this.patchUser.execute(userId, { displayName: 'Ops Test Updated' }, ctx);
      steps.push({ id: 'user_patch', label: 'Patch test user', status: 'pass', durationMs: Date.now() - t1 });
    } catch (e) {
      steps.push({ id: 'user_patch', label: 'Patch test user', status: 'fail', detail: String(e), durationMs: Date.now() - t1 });
    }

    const t2 = Date.now();
    try {
      await this.deleteUser.execute(userId, ctx);
      steps.push({ id: 'user_delete', label: 'Soft-delete test user', status: 'pass', durationMs: Date.now() - t2 });
    } catch (e) {
      steps.push({ id: 'user_delete', label: 'Soft-delete test user', status: 'fail', detail: String(e), durationMs: Date.now() - t2 });
    }

    return steps;
  }

  private async runPaymentLink(ctx: AdminRequestContext): Promise<TestStepResult> {
    const t0 = Date.now();
    try {
      const payee = await this.prisma.user.findFirst({
        where: { deletedAt: null, bankAccounts: { some: {} } },
        select: { id: true, email: true },
      });
      if (!payee) {
        return {
          id: 'payment_link',
          label: 'Create payment link',
          status: 'warn',
          detail: 'No user with bank account found — seed a user first',
          durationMs: Date.now() - t0,
        };
      }
      const link = await this.createLink.execute(
        { payeeUserId: payee.id, amountCents: 100, description: 'Ops test center link' },
        ctx,
      );
      return {
        id: 'payment_link',
        label: 'Create payment link',
        status: 'pass',
        detail: `/${link.shortCode} for ${payee.email}`,
        durationMs: Date.now() - t0,
      };
    } catch (e) {
      return {
        id: 'payment_link',
        label: 'Create payment link',
        status: 'fail',
        detail: String(e),
        durationMs: Date.now() - t0,
      };
    }
  }

  private async runWebhooks(): Promise<TestStepResult> {
    const t0 = Date.now();
    try {
      const count = await this.prisma.webhookEvent.count();
      return {
        id: 'webhooks',
        label: 'Webhooks table reachable',
        status: 'pass',
        detail: `${count} events`,
        durationMs: Date.now() - t0,
      };
    } catch (e) {
      return {
        id: 'webhooks',
        label: 'Webhooks table reachable',
        status: 'fail',
        detail: String(e),
        durationMs: Date.now() - t0,
      };
    }
  }
}
